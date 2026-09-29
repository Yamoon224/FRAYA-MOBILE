library;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/utils/geo_utils.dart';

class DriverHomeArrivalDetectionPolicy {
  const DriverHomeArrivalDetectionPolicy._();

  static bool isWithinArrivalRadius({
    required LatLng driverLocation,
    required LatLng destination,
    double thresholdMeters = AppConstants.driverDestinationArrivalRadiusMeters,
  }) {
    return geoDistanceMeters(driverLocation, destination) <= thresholdMeters;
  }

  static bool hasExitedArrivalZone({
    required LatLng driverLocation,
    required LatLng destination,
    double exitThresholdMeters =
        AppConstants.driverDestinationArrivalExitRadiusMeters,
  }) {
    return geoDistanceMeters(driverLocation, destination) >
        exitThresholdMeters;
  }

  static bool shouldPromptArrival({
    required bool isWithinRadius,
    required bool alreadyPromptedInZone,
    required DateTime? lastPromptAt,
    DateTime? now,
    Duration retriggerCooldown =
        AppConstants.driverDestinationArrivalPromptCooldown,
  }) {
    if (!isWithinRadius) return false;
    if (!alreadyPromptedInZone || lastPromptAt == null) return true;
    return (now ?? DateTime.now()).difference(lastPromptAt) >=
        retriggerCooldown;
  }
}
