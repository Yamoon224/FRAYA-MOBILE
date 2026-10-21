library;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/geo_utils.dart';

class DriverHomeLocationSyncPolicy {
  const DriverHomeLocationSyncPolicy._();

  static const double distanceThresholdMeters = 10;
  // Sans plancher, un chauffeur à 50 km/h franchit 10 m chaque seconde : ~1 requête/s.
  static const Duration minSendInterval = Duration(seconds: 3);
  static const Duration maxSilentInterval = Duration(seconds: 15);

  static bool shouldSend({
    required LatLng? previousLocation,
    required DateTime? lastSentAt,
    required LatLng nextLocation,
    DateTime? now,
  }) {
    if (previousLocation == null || lastSentAt == null) {
      return true;
    }

    final elapsed = (now ?? DateTime.now()).difference(lastSentAt);
    if (elapsed < minSendInterval) {
      return false;
    }

    final movedDistance = geoDistanceMeters(previousLocation, nextLocation);
    return movedDistance >= distanceThresholdMeters || elapsed >= maxSilentInterval;
  }
}
