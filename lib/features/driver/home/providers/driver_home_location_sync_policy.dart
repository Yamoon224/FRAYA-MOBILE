library;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/geo_utils.dart';

class DriverHomeLocationSyncPolicy {
  const DriverHomeLocationSyncPolicy._();

  static const double distanceThresholdMeters = 10;
  static const Duration maxSilentInterval = Duration(seconds: 5);

  static bool shouldSend({
    required LatLng? previousLocation,
    required DateTime? lastSentAt,
    required LatLng nextLocation,
    DateTime? now,
  }) {
    if (previousLocation == null || lastSentAt == null) {
      return true;
    }

    final movedDistance = geoDistanceMeters(previousLocation, nextLocation);
    if (movedDistance >= distanceThresholdMeters) {
      return true;
    }

    final currentTime = now ?? DateTime.now();
    return currentTime.difference(lastSentAt) >= maxSilentInterval;
  }
}
