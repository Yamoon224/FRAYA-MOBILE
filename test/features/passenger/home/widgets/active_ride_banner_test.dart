import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/router/route_names.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_check_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/pending_search_session_provider.dart';
import 'package:fraya_mobile/features/passenger/home/widgets/active_ride_banner.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _IdleBookingFlow extends BookingFlow {
  @override
  BookingFlowState build() => BookingFlowState.idle;
}

class _SearchingBookingFlow extends BookingFlow {
  @override
  BookingFlowState build() => BookingFlowState.searching;
}

class _FakePendingSearchSessionStore extends PendingSearchSessionStore {
  _FakePendingSearchSessionStore(this.session) : super(LocalStorage.instance);

  final PendingSearchSession? session;

  @override
  PendingSearchSession? read() => session;
}

void main() {
  testWidgets(
    'shows pending search banner and navigates to vehicle selection',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: ActiveRideBanner()),
          ),
          GoRoute(
            path: '/vehicle-selection',
            name: RouteNames.vehicleSelection,
            builder: (_, _) => const Scaffold(body: Text('vehicle screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingFlowProvider.overrideWith(_SearchingBookingFlow.new),
            activeRideCheckProvider.overrideWith((ref) async => null),
            pendingSearchSessionStoreProvider.overrideWithValue(
              _FakePendingSearchSessionStore(
                PendingSearchSession(
                  rideId: 'ride_pending_1',
                  startedAt: DateTime(2026, 6, 4),
                ),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      expect(find.text('Recherche d\'un chauffeur...'), findsOneWidget);

      await tester.tap(find.text('Recherche d\'un chauffeur...'));
      await tester.pumpAndSettle();

      expect(find.text('vehicle screen'), findsOneWidget);
    },
  );

  testWidgets('shows active ride banner from active ride controller', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingFlowProvider.overrideWith(_IdleBookingFlow.new),
          activeRideControllerProvider.overrideWithValue(
            _activeRide(RideStatus.accepted),
          ),
          activeRideCheckProvider.overrideWith((ref) async => null),
          pendingSearchSessionStoreProvider.overrideWithValue(
            _FakePendingSearchSessionStore(null),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ActiveRideBanner())),
      ),
    );

    expect(find.text('Chauffeur en route'), findsOneWidget);
  });

  testWidgets('hides banner without pending session or active ride', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingFlowProvider.overrideWith(_SearchingBookingFlow.new),
          activeRideCheckProvider.overrideWith((ref) async => null),
          pendingSearchSessionStoreProvider.overrideWithValue(
            _FakePendingSearchSessionStore(null),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ActiveRideBanner())),
      ),
    );

    expect(find.text('Recherche d\'un chauffeur...'), findsNothing);
    expect(find.text('Chauffeur en route'), findsNothing);
  });
}

ActiveRide _activeRide(RideStatus status) {
  return ActiveRide(
    rideId: 'ride_accepted_1',
    driverName: 'Jean',
    driverPhoto: 'assets/images/driver_placeholder.png',
    driverRating: 4.8,
    carModel: 'Toyota Corolla',
    carPlate: 'AA-123-BB',
    destinationAddress: 'Plateau',
    driverLocation: const LatLng(5.35, -4.01),
    destinationLocation: const LatLng(5.32, -4.00),
    status: status,
    estimatedPrice: 3000,
  );
}
