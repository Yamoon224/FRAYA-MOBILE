library;

import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../domain/models/ride_status.dart';

class DriverHomeMapRoutePolicy {
  const DriverHomeMapRoutePolicy._();

  static const double originRefreshThresholdMeters = 120;
  static const double destinationRefreshThresholdMeters = 10;
  static const Duration minRefreshInterval = Duration(seconds: 20);

  static bool shouldRefreshRoute({
    required LatLng previousOrigin,
    required LatLng previousDestination,
    required LatLng nextOrigin,
    required LatLng nextDestination,
    required DateTime? lastRefreshAt,
    DateTime? now,
  }) {
    final destinationShift = _distanceMeters(
      previousDestination,
      nextDestination,
    );
    if (destinationShift >= destinationRefreshThresholdMeters) {
      return true;
    }

    final originShift = _distanceMeters(previousOrigin, nextOrigin);
    if (originShift < originRefreshThresholdMeters) {
      return false;
    }

    if (lastRefreshAt == null) {
      return true;
    }

    final currentTime = now ?? DateTime.now();
    return currentTime.difference(lastRefreshAt) >= minRefreshInterval;
  }

  static String buildViewportKey({
    required LatLng destination,
    required RideStatus rideStatus,
  }) {
    return '${destination.latitude.toStringAsFixed(5)},'
        '${destination.longitude.toStringAsFixed(5)}|${rideStatus.name}';
  }

  static double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final sa = math.sin(dLat / 2);
    final sb = math.sin(dLng / 2);
    final h =
        sa * sa +
        math.cos(_toRadians(a.latitude)) *
            math.cos(_toRadians(b.latitude)) *
            sb *
            sb;
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadius * c;
  }

  static double _toRadians(double degree) => degree * (math.pi / 180);
}
