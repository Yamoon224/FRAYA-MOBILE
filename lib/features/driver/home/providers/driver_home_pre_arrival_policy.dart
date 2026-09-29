library;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/utils/geo_utils.dart';

class DriverHomePreArrivalPolicy {
  const DriverHomePreArrivalPolicy._();

  static bool isInPreArrivalZone({
    required LatLng driverLocation,
    required LatLng destination,
    double thresholdMeters = AppConstants.driverPreArrivalOffersRadiusMeters,
  }) {
    return geoDistanceMeters(driverLocation, destination) <= thresholdMeters;
  }
}
