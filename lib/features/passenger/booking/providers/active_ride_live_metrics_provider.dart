library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider, Ref;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/realtime/socket_health_state.dart';
import '../../../../core/utils/measurement_formatter.dart';
import '../../../../domain/models/active_ride.dart';
import '../../../../domain/models/ride_status.dart';
import '../../../../domain/repositories/directions_repository.dart';
import '../../../../shared/providers/realtime_providers.dart';
import 'active_ride_provider.dart';
import 'directions_dependencies.dart';
import 'active_ride_live_metrics.dart';

export 'active_ride_live_metrics.dart';

final activeRideLiveMetricsNowProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final activeRideLiveMetricsMinRecomputeIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 10),
);

final activeRideLiveMetricsMinRecomputeDistanceMetersProvider =
    Provider<double>((ref) => 50);

final activeRideLiveMetricsAverageSpeedKmhProvider = Provider<double>(
  (ref) => 25,
);

final activeRideLiveMetricsControllerProvider =
    StateNotifierProvider<
      ActiveRideLiveMetricsController,
      ActiveRideLiveMetrics
    >((ref) {
      final controller = ActiveRideLiveMetricsController(ref);
      ref.listen<ActiveRide?>(
        activeRideControllerProvider,
        (previous, next) => controller.onRideChanged(next),
      );
      ref.listen<SocketHealthState>(
        realtimeHealthStateProvider,
        (previous, next) => controller.onSocketHealthChanged(next),
      );
      return controller;
    });

class ActiveRideLiveMetricsController
    extends StateNotifier<ActiveRideLiveMetrics> {
  ActiveRideLiveMetricsController(this._ref)
    : super(
        ActiveRideLiveMetricsCalculator.fromRide(
          _ref.read(activeRideControllerProvider),
          now: _ref.read(activeRideLiveMetricsNowProvider)(),
          averageSpeedKmh: _ref.read(
            activeRideLiveMetricsAverageSpeedKmhProvider,
          ),
        ),
      );

  final Ref _ref;
  DateTime? _lastDirectionsAt;
  LatLng? _lastDirectionsOrigin;
  LatLng? _lastDirectionsDestination;
  int _requestToken = 0;

  void onRideChanged(ActiveRide? ride) {
    final fallback = ActiveRideLiveMetricsCalculator.fromRide(
      ride,
      now: _ref.read(activeRideLiveMetricsNowProvider)(),
      averageSpeedKmh: _ref.read(activeRideLiveMetricsAverageSpeedKmhProvider),
    );
    if (ride == null) {
      _resetDirectionsTracking();
      state = fallback;
      return;
    }

    if (_isSocketUnavailable(_ref.read(realtimeHealthStateProvider))) {
      state = fallback;
      return;
    }

    final destination = _resolveDestination(ride);
    if (destination == null) {
      state = fallback;
      return;
    }

    if (!_shouldRefreshDirections(ride.driverLocation, destination)) {
      if (state.source != ActiveRideLiveMetricsSource.directions) {
        state = fallback;
      }
      return;
    }

    unawaited(_refreshFromDirections(ride, fallback, destination));
  }

  void onSocketHealthChanged(SocketHealthState health) {
    if (_isSocketUnavailable(health)) {
      state = ActiveRideLiveMetricsCalculator.fromRide(
        _ref.read(activeRideControllerProvider),
        now: _ref.read(activeRideLiveMetricsNowProvider)(),
        averageSpeedKmh: _ref.read(
          activeRideLiveMetricsAverageSpeedKmhProvider,
        ),
      );
      return;
    }
    onRideChanged(_ref.read(activeRideControllerProvider));
  }

  bool _shouldRefreshDirections(LatLng origin, LatLng destination) {
    final now = _ref.read(activeRideLiveMetricsNowProvider)();
    final minDistance = _ref.read(
      activeRideLiveMetricsMinRecomputeDistanceMetersProvider,
    );
    final minInterval = _ref.read(
      activeRideLiveMetricsMinRecomputeIntervalProvider,
    );
    final destinationChanged =
        _lastDirectionsDestination == null ||
        ActiveRideLiveMetricsCalculator.distanceMeters(
              _lastDirectionsDestination!,
              destination,
            ) >=
            5;
    if (destinationChanged) {
      return true;
    }

    if (_lastDirectionsOrigin == null || _lastDirectionsAt == null) {
      return true;
    }

    final movedMeters = ActiveRideLiveMetricsCalculator.distanceMeters(
      _lastDirectionsOrigin!,
      origin,
    );
    if (movedMeters < minDistance) return false;

    final elapsed = now.difference(_lastDirectionsAt!);
    return elapsed >= minInterval;
  }

  Future<void> _refreshFromDirections(
    ActiveRide ride,
    ActiveRideLiveMetrics backend,
    LatLng destination,
  ) async {
    final requestId = ++_requestToken;
    final result = await _ref.read(getRouteDirectionsUseCaseProvider)(
      GetRouteDirectionsParams(
        origin: ride.driverLocation,
        destination: destination,
        includeAlternativeRoutes: false,
      ),
    );
    final directions = result.fold((_) => null, (value) => value);
    if (requestId != _requestToken) return;

    final route = directions?.mainRoute;
    if (route == null ||
        (route.durationText.isEmpty && route.distanceText.isEmpty)) {
      state = backend;
      return;
    }

    final now = _ref.read(activeRideLiveMetricsNowProvider)();
    final durationSeconds = route.durationInTrafficValue ?? route.durationValue;
    _lastDirectionsAt = now;
    _lastDirectionsOrigin = ride.driverLocation;
    _lastDirectionsDestination = destination;
    state = ActiveRideLiveMetrics(
      etaText: MeasurementFormatter.normalizeDuration(
        route.arrivalTime ?? route.durationText,
        fallback: backend.etaText,
      ),
      distanceText: MeasurementFormatter.normalizeDistance(
        route.distanceText,
        fallback: backend.distanceText,
      ),
      arrivalTimeText: ActiveRideLiveMetricsCalculator.arrivalTimeText(
        now,
        durationSeconds,
      ),
      lastUpdatedAt: now,
      source: ActiveRideLiveMetricsSource.directions,
    );
  }

  void _resetDirectionsTracking() {
    _lastDirectionsAt = null;
    _lastDirectionsOrigin = null;
    _lastDirectionsDestination = null;
    _requestToken++;
  }

  bool _isSocketUnavailable(SocketHealthState health) {
    return health == SocketHealthState.degraded ||
        health == SocketHealthState.offline;
  }

  static LatLng? _resolveDestination(ActiveRide ride) {
    if (ride.status == RideStatus.accepted ||
        ride.status == RideStatus.arrived) {
      return ride.pickupLocation;
    }
    if (ride.status == RideStatus.inProgress) {
      return ride.destinationLocation;
    }
    return null;
  }
}
