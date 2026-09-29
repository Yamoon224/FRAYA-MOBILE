library;

import 'package:flutter_riverpod/legacy.dart';

import '../../../../domain/models/ride_status.dart';
import 'driver_home_arrival_detection_policy.dart';
import 'driver_home_state.dart';

class DriverArrivalDetectionEvent {
  const DriverArrivalDetectionEvent({
    required this.rideId,
    required this.detectedAt,
  });

  final String rideId;
  final DateTime detectedAt;
}

mixin DriverHomeArrivalDetection on StateNotifier<DriverHomeState> {
  String? _arrivalTrackedRideId;
  bool _isInsideArrivalZone = false;
  DateTime? _lastArrivalPromptAt;

  void evaluateArrivalDetection() {
    state = applyArrivalDetectionToState(state);
  }

  DriverHomeState applyArrivalDetectionToState(DriverHomeState current) {
    final ride = current.activeRide;
    if (ride == null || ride.status != RideStatus.inProgress) {
      _resetArrivalTracking(null);
      return current;
    }
    _resetArrivalTracking(ride.rideId);

    final location = current.currentDriverLocation;
    if (location == null) return current;

    final isWithin = DriverHomeArrivalDetectionPolicy.isWithinArrivalRadius(
      driverLocation: location,
      destination: ride.destinationLocation,
    );

    if (!isWithin) {
      if (DriverHomeArrivalDetectionPolicy.hasExitedArrivalZone(
        driverLocation: location,
        destination: ride.destinationLocation,
      )) {
        _isInsideArrivalZone = false;
      }
      return current;
    }

    final shouldPrompt = DriverHomeArrivalDetectionPolicy.shouldPromptArrival(
      isWithinRadius: isWithin,
      alreadyPromptedInZone: _isInsideArrivalZone,
      lastPromptAt: _lastArrivalPromptAt,
    );
    _isInsideArrivalZone = true;
    if (!shouldPrompt) return current;

    _lastArrivalPromptAt = DateTime.now();
    return current.copyWith(
      arrivalDetectionEvent: DriverArrivalDetectionEvent(
        rideId: ride.rideId,
        detectedAt: _lastArrivalPromptAt!,
      ),
    );
  }

  void _resetArrivalTracking(String? rideId) {
    if (_arrivalTrackedRideId == rideId) return;
    _arrivalTrackedRideId = rideId;
    _isInsideArrivalZone = false;
    _lastArrivalPromptAt = null;
  }
}
