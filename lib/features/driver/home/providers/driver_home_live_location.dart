library;

import 'package:flutter_riverpod/legacy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../domain/models/driver_ride.dart';
import 'driver_home_state.dart';

mixin DriverHomeLiveLocation on StateNotifier<DriverHomeState> {
  Future<bool> markArrived({
    required String rideId,
    required double driverLat,
    required double driverLng,
  });

  DriverHomeState applyRealtimeLocationToState(DriverHomeState nextState) {
    final location = nextState.currentDriverLocation;
    final activeRide = nextState.activeRide;
    if (location == null || activeRide == null) {
      return nextState;
    }
    return nextState.copyWith(
      activeRide: activeRide.copyWith(driverLocation: location),
    );
  }

  void syncRealtimeLocation(LatLng? location, {double? heading}) {
    state = applyRealtimeLocationToState(
      state.copyWith(
        currentDriverLocation: location,
        currentDriverHeading: heading != null && heading >= 0 ? heading : null,
      ),
    );
  }

  Future<bool> markArrivedForRide(DriverRide ride) {
    final location =
        state.currentDriverLocation ?? ride.driverLocation ?? ride.pickupLocation;
    return markArrived(
      rideId: ride.rideId,
      driverLat: location.latitude,
      driverLng: location.longitude,
    );
  }
}
