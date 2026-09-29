import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_home_map_route_policy.dart';

void main() {
  test('skips route refresh for small movement within cooldown', () {
    final shouldRefresh = DriverHomeMapRoutePolicy.shouldRefreshRoute(
      previousOrigin: const LatLng(5.35, -4.01),
      previousDestination: const LatLng(5.36, -4.00),
      nextOrigin: const LatLng(5.3501, -4.0101),
      nextDestination: const LatLng(5.36, -4.00),
      lastRefreshAt: DateTime(2026, 6, 2, 12, 0, 0),
      now: DateTime(2026, 6, 2, 12, 0, 5),
    );

    expect(shouldRefresh, isFalse);
  });

  test('refreshes route after large origin shift and cooldown', () {
    final shouldRefresh = DriverHomeMapRoutePolicy.shouldRefreshRoute(
      previousOrigin: const LatLng(5.35, -4.01),
      previousDestination: const LatLng(5.36, -4.00),
      nextOrigin: const LatLng(5.3515, -4.0115),
      nextDestination: const LatLng(5.36, -4.00),
      lastRefreshAt: DateTime(2026, 6, 2, 12, 0, 0),
      now: DateTime(2026, 6, 2, 12, 0, 25),
    );

    expect(shouldRefresh, isTrue);
  });

  test('refreshes route immediately when destination changes materially', () {
    final shouldRefresh = DriverHomeMapRoutePolicy.shouldRefreshRoute(
      previousOrigin: const LatLng(5.35, -4.01),
      previousDestination: const LatLng(5.36, -4.00),
      nextOrigin: const LatLng(5.35001, -4.01001),
      nextDestination: const LatLng(5.361, -4.001),
      lastRefreshAt: DateTime(2026, 6, 2, 12, 0, 0),
      now: DateTime(2026, 6, 2, 12, 0, 5),
    );

    expect(shouldRefresh, isTrue);
  });

  test('viewport key changes when ride status changes', () {
    final acceptedKey = DriverHomeMapRoutePolicy.buildViewportKey(
      destination: const LatLng(5.36, -4.00),
      rideStatus: RideStatus.accepted,
    );
    final inProgressKey = DriverHomeMapRoutePolicy.buildViewportKey(
      destination: const LatLng(5.36, -4.00),
      rideStatus: RideStatus.inProgress,
    );

    expect(acceptedKey, isNot(inProgressKey));
  });
}
