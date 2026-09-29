import 'dart:math' as math;

class GeoDistanceUtils {
  const GeoDistanceUtils._();

  static int? distanceMeters({
    required double? originLat,
    required double? originLng,
    required double destinationLat,
    required double destinationLng,
  }) {
    if (originLat == null || originLng == null) return null;
    if (destinationLat == 0 && destinationLng == 0) return null;
    const earthRadius = 6371000.0;
    final dLat = _toRadians(destinationLat - originLat);
    final dLng = _toRadians(destinationLng - originLng);
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final haversine =
        sinLat * sinLat +
        math.cos(_toRadians(originLat)) *
            math.cos(_toRadians(destinationLat)) *
            sinLng *
            sinLng;
    final arc = 2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
    return (earthRadius * arc).round();
  }

  static double _toRadians(double value) => value * (math.pi / 180);
}
