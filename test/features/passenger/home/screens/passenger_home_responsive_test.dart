import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/services/geocoding_service.dart';
import 'package:fraya_mobile/core/services/home_navigation_notifier.dart';
import 'package:fraya_mobile/core/services/location_service.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/home/screens/passenger_home_screen.dart';
import 'package:fraya_mobile/features/passenger/home/widgets/destination_search_sheet.dart';
import 'package:fraya_mobile/features/passenger/home/widgets/home_address_pill.dart';
import 'package:fraya_mobile/features/passenger/home/widgets/home_bottom_sheet.dart';
import 'package:fraya_mobile/features/passenger/home/widgets/home_menu_button.dart';
import 'package:fraya_mobile/features/passenger/map/providers/nearby_drivers_provider.dart';
import 'package:fraya_mobile/shared/models/device_status_snapshot.dart';
import 'package:fraya_mobile/shared/providers/device_status_provider.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';
import 'package:fraya_mobile/shared/providers/recent_places_provider.dart';
import 'package:fraya_mobile/shared/providers/saved_places_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _IdleBookingFlow extends BookingFlow {
  @override
  BookingFlowState build() => BookingFlowState.idle;
}

class _EmptySavedPlacesNotifier extends SavedPlacesNotifier {
  @override
  Future<List<SavedAddress>> build() async => <SavedAddress>[];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sizesToTest = <Size>[
    Size(320, 568),
    Size(393, 852),
    Size(412, 915),
    Size(800, 1280),
    Size(1024, 1366),
  ];

  group('PassengerHomeScreen responsive', () {
    for (final size in sizesToTest) {
      testWidgets('renders stable overlays at ${size.width}x${size.height}', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        FlutterSecureStorage.setMockInitialValues({});
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bookingFlowProvider.overrideWith(_IdleBookingFlow.new),
              deviceStatusProvider.overrideWith(
                (ref) => Stream<DeviceStatusSnapshot>.value(
                  DeviceStatusSnapshot.initial(),
                ),
              ),
              passengerLocationSnapshotProvider.overrideWith(
                (ref) async => null,
              ),
              passengerFormattedAddressProvider.overrideWith(
                (ref) => 'Cocody, Angre',
              ),
              nearbyDriversProvider.overrideWithValue(const <NearbyDriver>[]),
              recentPlacesListProvider.overrideWith(
                (ref) async => <PlaceDetails>[],
              ),
            ],
            child: const MaterialApp(home: PassengerHomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomeMenuButton), findsOneWidget);
        expect(find.byType(HomeAddressPill), findsOneWidget);
        expect(find.byType(HomeBottomSheet), findsOneWidget);
        expect(
          find.byKey(const Key('fraya_google_map_test_placeholder')),
          findsOneWidget,
        );
        final exception = tester.takeException();
        if (exception is FlutterError) {
          final details = exception.diagnostics
              .map((node) => node.toStringDeep())
              .join('\n');
          debugPrint(details);
        }
        expect(exception, isNull);
      });
    }

    testWidgets('drawer opens and keeps bounded width on tablet', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(1024, 1366));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingFlowProvider.overrideWith(_IdleBookingFlow.new),
            deviceStatusProvider.overrideWith(
              (ref) => Stream<DeviceStatusSnapshot>.value(
                DeviceStatusSnapshot.initial(),
              ),
            ),
            passengerLocationSnapshotProvider.overrideWith((ref) async => null),
            passengerFormattedAddressProvider.overrideWith(
              (ref) => 'Cocody, Angre',
            ),
            nearbyDriversProvider.overrideWithValue(const <NearbyDriver>[]),
            recentPlacesListProvider.overrideWith(
              (ref) async => <PlaceDetails>[],
            ),
          ],
          child: const MaterialApp(home: PassengerHomeScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      final drawer = tester.widget<Drawer>(find.byType(Drawer).first);
      expect(drawer.width, isNotNull);
      expect(drawer.width!, inInclusiveRange(280, 420));
      expect(find.textContaining('Param'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('DestinationSearchSheet shifts above keyboard inset', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          passengerUserAddressProvider.overrideWith(
            (ref) async => <String, String>{
              'commune': 'Cocody',
              'quartier': 'Angre',
            },
          ),
          savedPlacesNotifierProvider.overrideWith(
            () => _EmptySavedPlacesNotifier(),
          ),
          nearbyLandmarksProvider.overrideWith((ref) async => <PlaceDetails>[]),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(393, 852),
              padding: EdgeInsets.only(top: 44),
              viewInsets: EdgeInsets.only(bottom: 280),
            ),
            child: const Scaffold(
              resizeToAvoidBottomInset: false,
              body: DestinationSearchSheet(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final animatedPadding = tester.widget<AnimatedPadding>(
      find.byType(AnimatedPadding).first,
    );
    expect(animatedPadding.padding.resolve(TextDirection.ltr).bottom, 280);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'opens destination search sheet when pending home intent exists',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      HomeNavigationNotifier.instance
          .consumeOpenDestinationSearchOnHomePending();
      HomeNavigationNotifier.instance.requestOpenDestinationSearchOnHome();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingFlowProvider.overrideWith(_IdleBookingFlow.new),
            deviceStatusProvider.overrideWith(
              (ref) => Stream<DeviceStatusSnapshot>.value(
                DeviceStatusSnapshot.initial(),
              ),
            ),
            passengerLocationSnapshotProvider.overrideWith((ref) async => null),
            passengerFormattedAddressProvider.overrideWith(
              (ref) => 'Cocody, Angre',
            ),
            nearbyDriversProvider.overrideWithValue(const <NearbyDriver>[]),
            recentPlacesListProvider.overrideWith(
              (ref) async => <PlaceDetails>[],
            ),
            savedPlacesNotifierProvider.overrideWith(
              () => _EmptySavedPlacesNotifier(),
            ),
            nearbyLandmarksProvider.overrideWith(
              (ref) async => <PlaceDetails>[],
            ),
          ],
          child: const MaterialApp(home: PassengerHomeScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DestinationSearchSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home snapshot refreshes on startup and resume without enabling continuous tracking',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final fakeLocationService = _FakeLocationService();

      final container = ProviderContainer(
        overrides: [
          bookingFlowProvider.overrideWith(_IdleBookingFlow.new),
          locationServiceProvider.overrideWith((ref) => fakeLocationService),
          passengerFormattedAddressProvider.overrideWith(
            (ref) => 'Cocody, Angre',
          ),
          nearbyDriversProvider.overrideWithValue(const <NearbyDriver>[]),
          recentPlacesListProvider.overrideWith(
            (ref) async => <PlaceDetails>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PassengerHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeLocationService.currentPositionCallCount, 1);
      expect(container.read(locationTrackingRequestCountProvider), 0);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(fakeLocationService.currentPositionCallCount, 2);
      expect(container.read(locationTrackingRequestCountProvider), 0);
    },
  );

  testWidgets(
    'opening address search sheet triggers a fresh passenger snapshot read',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final fakeLocationService = _FakeLocationService();

      final container = ProviderContainer(
        overrides: [
          bookingFlowProvider.overrideWith(_IdleBookingFlow.new),
          locationServiceProvider.overrideWith((ref) => fakeLocationService),
          geocodingServiceProvider.overrideWith(
            (ref) => _FakeGeocodingService(),
          ),
          nearbyDriversProvider.overrideWithValue(const <NearbyDriver>[]),
          recentPlacesListProvider.overrideWith(
            (ref) async => <PlaceDetails>[],
          ),
          savedPlacesNotifierProvider.overrideWith(
            () => _EmptySavedPlacesNotifier(),
          ),
          nearbyLandmarksProvider.overrideWith((ref) async => <PlaceDetails>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PassengerHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeLocationService.currentPositionCallCount, 1);

      await tester.tap(find.text('Ou allez-vous ?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DestinationSearchSheet), findsOneWidget);
      expect(fakeLocationService.currentPositionCallCount, 2);
      expect(container.read(locationTrackingRequestCountProvider), 0);
    },
  );

  testWidgets(
    'blocks destination search while passenger location is still loading',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final pendingLocation = Completer<Position?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingFlowProvider.overrideWith(_IdleBookingFlow.new),
            deviceStatusProvider.overrideWith(
              (ref) => Stream<DeviceStatusSnapshot>.value(
                DeviceStatusSnapshot.initial(),
              ),
            ),
            passengerLocationSnapshotProvider.overrideWith(
              (ref) => pendingLocation.future,
            ),
            passengerFormattedAddressProvider.overrideWith(
              (ref) => 'Recherche...',
            ),
            nearbyDriversProvider.overrideWithValue(const <NearbyDriver>[]),
            recentPlacesListProvider.overrideWith(
              (ref) async => <PlaceDetails>[],
            ),
          ],
          child: const MaterialApp(home: PassengerHomeScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Ou allez-vous ?'));
      await tester.pump();

      expect(find.byType(DestinationSearchSheet), findsNothing);
      expect(
        find.text(
          passengerLocationBlockingMessage(PassengerLocationReadiness.loading),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 10));
    },
  );

  testWidgets(
    'blocks recent address selection while passenger location is still loading',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final pendingLocation = Completer<Position?>();
      final recentPlace = PlaceDetails(
        placeId: 'recent_home',
        name: 'Maison',
        address: 'Cocody, Angre',
        latitude: 5.35,
        longitude: -4.01,
      );

      final container = ProviderContainer(
        overrides: [
          bookingFlowProvider.overrideWith(_IdleBookingFlow.new),
          deviceStatusProvider.overrideWith(
            (ref) => Stream<DeviceStatusSnapshot>.value(
              DeviceStatusSnapshot.initial(),
            ),
          ),
          passengerLocationSnapshotProvider.overrideWith(
            (ref) => pendingLocation.future,
          ),
          passengerFormattedAddressProvider.overrideWith(
            (ref) => 'Recherche...',
          ),
          nearbyDriversProvider.overrideWithValue(const <NearbyDriver>[]),
          recentPlacesListProvider.overrideWith(
            (ref) async => <PlaceDetails>[recentPlace],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PassengerHomeScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Maison'));
      await tester.pump();

      expect(container.read(selectedDestinationProvider), isNull);
      expect(
        find.text(
          passengerLocationBlockingMessage(PassengerLocationReadiness.loading),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 10));
    },
  );
}

class _FakeLocationService extends LocationService {
  int currentPositionCallCount = 0;
  int positionStreamCallCount = 0;

  @override
  Future<Position?> getCurrentPosition() async {
    currentPositionCallCount++;
    return Position(
      longitude: -4.01,
      latitude: 5.35,
      timestamp: DateTime(2026, 6, 24),
      accuracy: 8,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Future<Position?> getLastKnownPosition() async => null;

  @override
  Stream<Position> getPositionStream() {
    positionStreamCallCount++;
    return const Stream<Position>.empty();
  }
}

class _FakeGeocodingService extends GeocodingService {
  @override
  Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
    return <String, String>{
      'commune': 'Cocody',
      'quartier': 'Angre',
      'formatted': 'Cocody, Angre',
    };
  }
}
