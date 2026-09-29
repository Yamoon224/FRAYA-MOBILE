import 'package:flutter_riverpod/legacy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';

part 'active_ride_provider.g.dart';

@riverpod
class ActiveRideController extends _$ActiveRideController {
  @override
  ActiveRide? build() => null;

  void initialize(ActiveRide ride) {
    state = ride;
  }

  void updateStatus(RideStatus status) {
    if (state == null) return;
    state = state!.copyWith(status: status);
  }

  void updateLocation(LatLng location) {
    if (state == null) return;
    state = state!.copyWith(driverLocation: location);
  }

  void clear() {
    state = null;
  }
}

final completedRideControllerProvider =
    StateNotifierProvider<CompletedRideController, ActiveRide?>((ref) {
      return CompletedRideController();
    });

class CompletedRideController extends StateNotifier<ActiveRide?> {
  CompletedRideController() : super(null);

  void initialize(ActiveRide ride) {
    state = ride;
  }

  void clear() {
    state = null;
  }
}
