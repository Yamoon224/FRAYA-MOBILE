library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/models/directions_models.dart';
import '../../../../core/models/places_models.dart';
import '../../../../domain/models/ride_status.dart';
import '../../../../domain/repositories/directions_repository.dart';
import '../../../../shared/providers/places_provider.dart';
import 'active_ride_provider.dart';
import 'directions_dependencies.dart';

enum ActiveRideMapRouteTarget { pickup, destination }

class ActiveRideMapRouteQuery {
  const ActiveRideMapRouteQuery({
    required this.rideId,
    required this.target,
    required this.origin,
    required this.destination,
  });

  final String rideId;
  final ActiveRideMapRouteTarget target;
  final LatLng origin;
  final LatLng destination;

  bool hasSameContext(ActiveRideMapRouteQuery other) {
    return rideId == other.rideId &&
        target == other.target &&
        _samePoint(destination, other.destination);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveRideMapRouteQuery &&
        rideId == other.rideId &&
        target == other.target &&
        _samePoint(origin, other.origin) &&
        _samePoint(destination, other.destination);
  }

  @override
  int get hashCode => Object.hash(
    rideId,
    target,
    _rounded(origin.latitude),
    _rounded(origin.longitude),
    _rounded(destination.latitude),
    _rounded(destination.longitude),
  );

  static bool _samePoint(LatLng first, LatLng second) {
    return _rounded(first.latitude) == _rounded(second.latitude) &&
        _rounded(first.longitude) == _rounded(second.longitude);
  }

  static double _rounded(double value) => (value * 10000).round() / 10000;
}

class ActiveRideMapRouteState {
  const ActiveRideMapRouteState({
    this.query,
    this.directions,
    this.isRefreshing = false,
  });

  final ActiveRideMapRouteQuery? query;
  final DirectionsResult? directions;
  final bool isRefreshing;
}

final activeRideMapRouteQueryProvider = Provider<ActiveRideMapRouteQuery?>((
  ref,
) {
  final ride = ref.watch(activeRideControllerProvider);
  if (ride == null || !_isValidCoordinate(ride.driverLocation)) return null;

  final target = _targetForStatus(ride.status);
  if (target == null) return null;

  final destination = switch (target) {
    ActiveRideMapRouteTarget.pickup =>
      _validPoint(ride.pickupLocation) ??
          _toLatLngIfValid(ref.watch(selectedPickupProvider)),
    ActiveRideMapRouteTarget.destination =>
      _validPoint(ride.destinationLocation) ??
          _toLatLngIfValid(ref.watch(selectedDestinationProvider)),
  };
  if (destination == null) return null;

  return ActiveRideMapRouteQuery(
    rideId: ride.rideId,
    target: target,
    origin: ride.driverLocation,
    destination: destination,
  );
});

final activeRideMapRouteProvider =
    StateNotifierProvider.autoDispose<
      ActiveRideMapRouteController,
      ActiveRideMapRouteState
    >((ref) {
      final controller = ActiveRideMapRouteController(ref);
      ref.listen<ActiveRideMapRouteQuery?>(
        activeRideMapRouteQueryProvider,
        (_, next) => controller.updateQuery(next),
        fireImmediately: true,
      );
      return controller;
    });

class ActiveRideMapRouteController
    extends StateNotifier<ActiveRideMapRouteState> {
  ActiveRideMapRouteController(this._ref)
    : super(const ActiveRideMapRouteState());

  final Ref _ref;
  int _requestToken = 0;

  void updateQuery(ActiveRideMapRouteQuery? query) {
    if (query == null) {
      _requestToken++;
      state = const ActiveRideMapRouteState();
      return;
    }
    if (state.query == query) return;

    final previousDirections = state.query?.hasSameContext(query) == true
        ? state.directions
        : null;
    state = ActiveRideMapRouteState(
      query: query,
      directions: previousDirections,
      isRefreshing: true,
    );
    _loadDirections(query, previousDirections);
  }

  Future<void> _loadDirections(
    ActiveRideMapRouteQuery query,
    DirectionsResult? previousDirections,
  ) async {
    final requestToken = ++_requestToken;
    final result = await _ref.read(getRouteDirectionsUseCaseProvider)(
      GetRouteDirectionsParams(
        origin: query.origin,
        destination: query.destination,
        includeAlternativeRoutes: false,
      ),
    );
    if (requestToken != _requestToken) return;

    final directions = result.fold(
      (_) => previousDirections,
      (value) =>
          value == null || value.routes.isEmpty ? previousDirections : value,
    );
    state = ActiveRideMapRouteState(query: query, directions: directions);
  }
}

ActiveRideMapRouteTarget? _targetForStatus(RideStatus status) {
  return switch (status) {
    RideStatus.accepted ||
    RideStatus.arrived => ActiveRideMapRouteTarget.pickup,
    RideStatus.inProgress => ActiveRideMapRouteTarget.destination,
    _ => null,
  };
}

bool _isValidCoordinate(LatLng? point) => _validPoint(point) != null;

LatLng? _validPoint(LatLng? point) {
  if (point == null) return null;
  if (point.latitude < -90 || point.latitude > 90) return null;
  if (point.longitude < -180 || point.longitude > 180) return null;
  if (point.latitude == 0 && point.longitude == 0) return null;
  return point;
}

LatLng? _toLatLngIfValid(PlaceDetails? place) {
  if (place == null) return null;
  return _validPoint(LatLng(place.latitude, place.longitude));
}
