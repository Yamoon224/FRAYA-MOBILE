import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fraya_mobile/core/router/passenger_router.dart';
import 'package:fraya_mobile/core/router/route_names.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

void main() {
  group('resolvePassengerRedirect', () {
    test('keeps splash while passenger auth session is bootstrapping', () {
      final redirect = resolvePassengerRedirect(
        authState: AuthState(status: AuthStatus.idle),
        currentPath: RoutePaths.splash,
        hasCompletedOnboarding: true,
        pendingSearchCleanupAsync: const AsyncData<void>(null),
        activeRideAsync: const AsyncLoading<ActiveRide?>(),
      );

      expect(redirect, isNull);
    });

    test('redirects splash to vehicle selection when accepted ride exists', () {
      final redirect = resolvePassengerRedirect(
        authState: AuthState(
          status: AuthStatus.authenticated,
          userData: const {'id': 7},
        ),
        currentPath: RoutePaths.splash,
        hasCompletedOnboarding: true,
        pendingSearchCleanupAsync: const AsyncData<void>(null),
        activeRideAsync: const AsyncData<ActiveRide?>(
          ActiveRide(
            rideId: 'ride_accepted_1',
            driverName: 'Jean',
            driverPhoto: 'assets/images/driver_placeholder.png',
            driverRating: 4.8,
            carModel: 'Toyota Corolla',
            carPlate: 'AA-123-BB',
            destinationAddress: 'Plateau, Avenue Chardy',
            driverLocation: LatLng(5.35, -4.01),
            destinationLocation: LatLng(5.32, -4.00),
            status: RideStatus.accepted,
            estimatedPrice: 3000,
          ),
        ),
      );

      expect(redirect, RoutePaths.vehicleSelection);
    });

    test('redirects splash to passenger home when no active ride exists', () {
      final redirect = resolvePassengerRedirect(
        authState: AuthState(
          status: AuthStatus.authenticated,
          userData: const {'id': 7},
        ),
        currentPath: RoutePaths.splash,
        hasCompletedOnboarding: true,
        pendingSearchCleanupAsync: const AsyncData<void>(null),
        activeRideAsync: const AsyncData<ActiveRide?>(null),
      );

      expect(redirect, RoutePaths.passengerHome);
    });

    test('keeps splash while pending search cleanup is running', () {
      final redirect = resolvePassengerRedirect(
        authState: AuthState(
          status: AuthStatus.authenticated,
          userData: const {'id': 7},
        ),
        currentPath: RoutePaths.splash,
        hasCompletedOnboarding: true,
        pendingSearchCleanupAsync: const AsyncLoading<void>(),
        activeRideAsync: const AsyncData<ActiveRide?>(null),
      );

      expect(redirect, isNull);
    });
  });
}
