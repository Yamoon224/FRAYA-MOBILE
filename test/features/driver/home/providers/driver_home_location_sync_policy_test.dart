import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_location_sync_policy.dart';

void main() {
  test('sends first location immediately', () {
    final shouldSend = DriverHomeLocationSyncPolicy.shouldSend(
      previousLocation: null,
      lastSentAt: null,
      nextLocation: const LatLng(5.35, -4.01),
      now: DateTime(2026, 6, 2, 12, 0, 0),
    );

    expect(shouldSend, isTrue);
  });

  test('skips update when movement and time are both below thresholds', () {
    final shouldSend = DriverHomeLocationSyncPolicy.shouldSend(
      previousLocation: const LatLng(5.35, -4.01),
      lastSentAt: DateTime(2026, 6, 2, 12, 0, 0),
      nextLocation: const LatLng(5.35001, -4.01001),
      now: DateTime(2026, 6, 2, 12, 0, 5),
    );

    expect(shouldSend, isFalse);
  });

  test('sends update after silent interval even with small movement', () {
    final shouldSend = DriverHomeLocationSyncPolicy.shouldSend(
      previousLocation: const LatLng(5.35, -4.01),
      lastSentAt: DateTime(2026, 6, 2, 12, 0, 0),
      nextLocation: const LatLng(5.35001, -4.01001),
      now: DateTime(2026, 6, 2, 12, 0, 16),
    );

    expect(shouldSend, isTrue);
  });

  test('throttles large movements to the minimum send interval', () {
    final tooSoon = DriverHomeLocationSyncPolicy.shouldSend(
      previousLocation: const LatLng(5.35, -4.01),
      lastSentAt: DateTime(2026, 6, 2, 12, 0, 0),
      nextLocation: const LatLng(5.3505, -4.01),
      now: DateTime(2026, 6, 2, 12, 0, 1),
    );
    final afterInterval = DriverHomeLocationSyncPolicy.shouldSend(
      previousLocation: const LatLng(5.35, -4.01),
      lastSentAt: DateTime(2026, 6, 2, 12, 0, 0),
      nextLocation: const LatLng(5.3505, -4.01),
      now: DateTime(2026, 6, 2, 12, 0, 3),
    );

    expect(tooSoon, isFalse);
    expect(afterInterval, isTrue);
  });

  group('boundaries', () {
    const origin = LatLng(5.35, -4.01);
    // ~55 m plus au nord : bien au-dessus du seuil de 10 m.
    const farAway = LatLng(5.3505, -4.01);
    // ~1,5 m : sous le seuil de 10 m.
    const nearby = LatLng(5.35001, -4.01001);
    final lastSentAt = DateTime(2026, 6, 2, 12, 0, 0);

    bool decide(LatLng next, Duration elapsed) =>
        DriverHomeLocationSyncPolicy.shouldSend(
          previousLocation: origin,
          lastSentAt: lastSentAt,
          nextLocation: next,
          now: lastSentAt.add(elapsed),
        );

    test('exposes the production thresholds', () {
      expect(
        DriverHomeLocationSyncPolicy.minSendInterval,
        const Duration(seconds: 3),
      );
      expect(
        DriverHomeLocationSyncPolicy.maxSilentInterval,
        const Duration(seconds: 15),
      );
      expect(DriverHomeLocationSyncPolicy.distanceThresholdMeters, 10);
    });

    test('large movement: blocked just under 3 s, sent at exactly 3 s', () {
      expect(decide(farAway, const Duration(milliseconds: 2999)), isFalse);
      expect(decide(farAway, const Duration(seconds: 3)), isTrue);
    });

    test('small movement: silent just under 15 s, sent at exactly 15 s', () {
      expect(decide(nearby, const Duration(seconds: 3)), isFalse);
      expect(decide(nearby, const Duration(milliseconds: 14999)), isFalse);
      expect(decide(nearby, const Duration(seconds: 15)), isTrue);
    });

    test('no movement at all still sends a heartbeat at 15 s', () {
      expect(decide(origin, const Duration(seconds: 14)), isFalse);
      expect(decide(origin, const Duration(seconds: 15)), isTrue);
    });

    test('no update within 3 s even at 0 s elapsed', () {
      expect(decide(farAway, Duration.zero), isFalse);
    });

    test('clock going backwards never sends', () {
      expect(decide(farAway, const Duration(seconds: -5)), isFalse);
    });

    test('null previous location sends regardless of timing', () {
      final shouldSend = DriverHomeLocationSyncPolicy.shouldSend(
        previousLocation: null,
        lastSentAt: lastSentAt,
        nextLocation: origin,
        now: lastSentAt,
      );
      expect(shouldSend, isTrue);
    });

    test('null lastSentAt sends regardless of distance', () {
      final shouldSend = DriverHomeLocationSyncPolicy.shouldSend(
        previousLocation: origin,
        lastSentAt: null,
        nextLocation: origin,
        now: lastSentAt,
      );
      expect(shouldSend, isTrue);
    });
  });
}
