library;

import 'dart:math' as math;

import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../domain/models/active_ride.dart';
import '../../../../domain/models/ride_status.dart';
import 'active_ride_provider.dart';

const _arrivalProgressCompleteDistanceMeters = 5.0;

final activeRideArrivalProgressProvider =
    StateNotifierProvider<
      ActiveRideArrivalProgressController,
      ActiveRideArrivalProgress
    >((ref) {
      final controller = ActiveRideArrivalProgressController();
      ref.listen<ActiveRide?>(
        activeRideControllerProvider,
        (previous, next) => controller.onRideChanged(next),
      );
      controller.onRideChanged(ref.read(activeRideControllerProvider));
      return controller;
    });

class ActiveRideArrivalProgress {
  const ActiveRideArrivalProgress({
    required this.progress,
    required this.isIndeterminate,
  });

  final double progress;
  final bool isIndeterminate;

  static const indeterminate = ActiveRideArrivalProgress(
    progress: 0,
    isIndeterminate: true,
  );
}

class ActiveRideArrivalProgressController
    extends StateNotifier<ActiveRideArrivalProgress> {
  ActiveRideArrivalProgressController()
    : super(ActiveRideArrivalProgress.indeterminate);

  String? _rideId;
  double? _initialDistanceMeters;

  void onRideChanged(ActiveRide? ride) {
    if (ride == null || ride.status != RideStatus.accepted) {
      _reset();
      return;
    }

    final pickup = ride.pickupLocation;
    if (pickup == null) {
      _rideId = ride.rideId;
      _initialDistanceMeters = null;
      state = ActiveRideArrivalProgress.indeterminate;
      return;
    }

    _updateProgress(ride, pickup);
  }

  void _updateProgress(ActiveRide ride, LatLng pickup) {
    if (_rideId != ride.rideId) {
      _rideId = ride.rideId;
      _initialDistanceMeters = null;
    }

    final currentDistanceMeters = _distanceMeters(ride.driverLocation, pickup);
    _initialDistanceMeters ??= currentDistanceMeters;
    final initialDistanceMeters = _initialDistanceMeters!;

    if (initialDistanceMeters <= _arrivalProgressCompleteDistanceMeters) {
      state = const ActiveRideArrivalProgress(
        progress: 1,
        isIndeterminate: false,
      );
      return;
    }

    final progress = 1 - (currentDistanceMeters / initialDistanceMeters);
    state = ActiveRideArrivalProgress(
      progress: progress.clamp(0, 1).toDouble(),
      isIndeterminate: false,
    );
  }

  void _reset() {
    _rideId = null;
    _initialDistanceMeters = null;
    state = ActiveRideArrivalProgress.indeterminate;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final haversine =
        sinLat * sinLat +
        math.cos(_toRadians(a.latitude)) *
            math.cos(_toRadians(b.latitude)) *
            sinLng *
            sinLng;
    final arc = 2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
    return earthRadius * arc;
  }

  double _toRadians(double value) => value * (math.pi / 180);
}
