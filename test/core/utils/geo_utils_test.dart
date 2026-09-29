import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fraya_mobile/core/utils/geo_utils.dart';

void main() {
  group('geoDistanceMeters', () {
    test('returns 0 for identical points', () {
      const point = LatLng(5.36, -4.008);
      expect(geoDistanceMeters(point, point), 0.0);
    });

    test('returns ~111km for 1 degree of latitude', () {
      const a = LatLng(0, 0);
      const b = LatLng(1, 0);
      final dist = geoDistanceMeters(a, b);
      expect(dist, greaterThan(110000));
      expect(dist, lessThan(112000));
    });

    test('returns ~400m for two nearby points in Abidjan', () {
      const a = LatLng(5.3600, -4.0083);
      const b = LatLng(5.3636, -4.0083);
      final dist = geoDistanceMeters(a, b);
      expect(dist, greaterThan(350));
      expect(dist, lessThan(450));
    });

    test('is symmetric', () {
      const a = LatLng(5.36, -4.008);
      const b = LatLng(5.37, -4.010);
      expect(geoDistanceMeters(a, b), closeTo(geoDistanceMeters(b, a), 0.001));
    });
  });
}
