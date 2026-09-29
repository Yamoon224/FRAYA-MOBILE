import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_arrival_detection_policy.dart';

void main() {
  const abidjan = LatLng(5.3600, -4.0083);

  LatLng northOf(LatLng base, double meters) {
    return LatLng(base.latitude + meters / 111320, base.longitude);
  }

  // ~20m au nord (dans le rayon d'arrivée de 30m)
  final withinRadius = northOf(abidjan, 20);
  // ~35m au nord (hors rayon d'arrivée de 30m, mais dans le rayon de sortie de 45m)
  final justOutsideRadius = northOf(abidjan, 35);
  // ~50m au nord (au-delà du rayon de sortie de 45m)
  final beyondExitRadius = northOf(abidjan, 50);

  group('DriverHomeArrivalDetectionPolicy.isWithinArrivalRadius', () {
    test('returns true when driver is within the 30m threshold', () {
      expect(
        DriverHomeArrivalDetectionPolicy.isWithinArrivalRadius(
          driverLocation: withinRadius,
          destination: abidjan,
        ),
        isTrue,
      );
    });

    test('returns false when driver is beyond the 30m threshold', () {
      expect(
        DriverHomeArrivalDetectionPolicy.isWithinArrivalRadius(
          driverLocation: justOutsideRadius,
          destination: abidjan,
        ),
        isFalse,
      );
    });

    test('returns true when driver is exactly at destination', () {
      expect(
        DriverHomeArrivalDetectionPolicy.isWithinArrivalRadius(
          driverLocation: abidjan,
          destination: abidjan,
        ),
        isTrue,
      );
    });
  });

  group('DriverHomeArrivalDetectionPolicy.hasExitedArrivalZone', () {
    test('returns false while within the 45m exit threshold', () {
      expect(
        DriverHomeArrivalDetectionPolicy.hasExitedArrivalZone(
          driverLocation: justOutsideRadius,
          destination: abidjan,
        ),
        isFalse,
      );
    });

    test('returns true once beyond the 45m exit threshold', () {
      expect(
        DriverHomeArrivalDetectionPolicy.hasExitedArrivalZone(
          driverLocation: beyondExitRadius,
          destination: abidjan,
        ),
        isTrue,
      );
    });
  });

  group('DriverHomeArrivalDetectionPolicy.shouldPromptArrival', () {
    test('returns false when driver is outside the radius', () {
      expect(
        DriverHomeArrivalDetectionPolicy.shouldPromptArrival(
          isWithinRadius: false,
          alreadyPromptedInZone: false,
          lastPromptAt: null,
        ),
        isFalse,
      );
    });

    test('returns true on first entry into the zone', () {
      expect(
        DriverHomeArrivalDetectionPolicy.shouldPromptArrival(
          isWithinRadius: true,
          alreadyPromptedInZone: false,
          lastPromptAt: null,
        ),
        isTrue,
      );
    });

    test(
      'returns false while staying in zone before the cooldown elapses',
      () {
        final now = DateTime(2026, 1, 1, 12, 0);
        expect(
          DriverHomeArrivalDetectionPolicy.shouldPromptArrival(
            isWithinRadius: true,
            alreadyPromptedInZone: true,
            lastPromptAt: now.subtract(const Duration(minutes: 1)),
            now: now,
            retriggerCooldown: const Duration(minutes: 3),
          ),
          isFalse,
        );
      },
    );

    test('returns true once the retrigger cooldown has elapsed', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      expect(
        DriverHomeArrivalDetectionPolicy.shouldPromptArrival(
          isWithinRadius: true,
          alreadyPromptedInZone: true,
          lastPromptAt: now.subtract(const Duration(minutes: 4)),
          now: now,
          retriggerCooldown: const Duration(minutes: 3),
        ),
        isTrue,
      );
    });
  });
}
