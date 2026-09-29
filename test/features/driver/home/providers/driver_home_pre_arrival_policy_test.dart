import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_pre_arrival_policy.dart';

void main() {
  const abidjan = LatLng(5.3600, -4.0083);

  // ~400m au nord
  const nearDestination = LatLng(5.3636, -4.0083);
  // ~1.2km au nord
  const farDestination = LatLng(5.3708, -4.0083);

  group('DriverHomePreArrivalPolicy.isInPreArrivalZone', () {
    test('returns true when driver is within threshold', () {
      expect(
        DriverHomePreArrivalPolicy.isInPreArrivalZone(
          driverLocation: abidjan,
          destination: nearDestination,
          thresholdMeters: 500,
        ),
        isTrue,
      );
    });

    test('returns false when driver is beyond threshold', () {
      expect(
        DriverHomePreArrivalPolicy.isInPreArrivalZone(
          driverLocation: abidjan,
          destination: farDestination,
          thresholdMeters: 500,
        ),
        isFalse,
      );
    });

    test('returns true just inside the threshold boundary', () {
      // ~490m au nord d'Abidjan (5.3644 ≈ 489m)
      const boundary = LatLng(5.3644, -4.0083);
      final result = DriverHomePreArrivalPolicy.isInPreArrivalZone(
        driverLocation: abidjan,
        destination: boundary,
        thresholdMeters: 500,
      );
      expect(result, isTrue);
    });

    test('uses default threshold from AppConstants', () {
      expect(
        DriverHomePreArrivalPolicy.isInPreArrivalZone(
          driverLocation: abidjan,
          destination: nearDestination,
        ),
        isTrue,
      );
    });

    test('returns true when driver is at destination', () {
      expect(
        DriverHomePreArrivalPolicy.isInPreArrivalZone(
          driverLocation: abidjan,
          destination: abidjan,
          thresholdMeters: 500,
        ),
        isTrue,
      );
    });
  });
}
