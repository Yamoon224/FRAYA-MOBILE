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
}
