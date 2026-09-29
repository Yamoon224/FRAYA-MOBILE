import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
import 'package:fraya_mobile/core/services/passenger_ride_alert_sound_service.dart';
import 'package:fraya_mobile/core/services/passenger_settings_service.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/login_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step3_usecase.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_check_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_route_refresh_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/pending_search_session_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_categories_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/route_directions_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/selected_route_index_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/booking_flow_listeners.dart';
import 'package:fraya_mobile/features/passenger/settings/providers/passenger_settings_provider.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/passenger_ride_alert_sound_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';
import 'package:fraya_mobile/shared/widgets/confirmation_action_column.dart';

class _RoutePreviewBookingFlow extends BookingFlow {
  @override
  BookingFlowState build() => BookingFlowState.routePreview;
}

class _TimeoutBookingFlow extends BookingFlow {
  static int startSearchCalls = 0;

  @override
  BookingFlowState build() => BookingFlowState.routePreview;

  @override
  Future<void> startSearching() async {
    startSearchCalls++;
    state = BookingFlowState.searching;
  }
}

class _ConflictBookingFlow extends BookingFlow {
  int resetCalls = 0;
  int cancelExistingAndRetryCalls = 0;

  @override
  BookingFlowState build() => BookingFlowState.routePreview;

  void triggerConflict() {
    state = BookingFlowState.activeRideConflict;
  }

  @override
  void reset() {
    resetCalls++;
    state = BookingFlowState.idle;
  }

  @override
  Future<void> cancelExistingAndRetry() async {
    cancelExistingAndRetryCalls++;
    state = BookingFlowState.searching;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'passenger-token',
      'auth_user_data': '{"id":7}',
    });
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();
  });

  testWidgets(
    'restoring an active ride does not trigger manual refresh or pricing modal',
    (tester) async {
      final repository = _FakeBookingRepository();
      final container = ProviderContainer(
        overrides: [
          passengerAuthProvider.overrideWith(
            (ref) => _TestPassengerAuthNotifier(
              AuthState(status: AuthStatus.authenticated, userData: {'id': 7}),
            ),
          ),
          activeRideCheckProvider.overrideWith((ref) async => null),
          passengerBookingRepositoryProvider.overrideWithValue(repository),
          routeDirectionsProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: BookingFlowListeners(
                onNavigateToSearch: () {},
                onExpandSheet: () {},
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      );

      container
          .read(bookingFlowProvider.notifier)
          .restoreFromActiveRide(
            const ActiveRide(
              rideId: 'ride_active_1',
              driverName: 'Chauffeur',
              driverPhoto: 'assets/images/driver_placeholder.png',
              driverRating: 4.8,
              carModel: 'Toyota Corolla',
              carPlate: 'AA-123-BB',
              pickupAddress: 'Cocody, Angre',
              destinationAddress: 'Plateau, Avenue Chardy',
              driverLocation: LatLng(5.35, -4.01),
              pickupLocation: LatLng(5.36, -4.02),
              destinationLocation: LatLng(5.32, -4.00),
              status: RideStatus.accepted,
              estimatedPrice: 3000,
            ),
          );
      await tester.pump();

      expect(
        container.read(bookingFlowProvider),
        BookingFlowState.driverAssigned,
      );
      expect(container.read(bookingManualRefreshTriggerProvider), 0);
      expect(
        find.textContaining("Impossible d'actualiser le prix"),
        findsNothing,
      );

      container.read(bookingFlowProvider.notifier).reset();
      await tester.pump();
    },
  );

  testWidgets(
    'changing destination in route preview still triggers route refresh',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          bookingFlowProvider.overrideWith(_RoutePreviewBookingFlow.new),
          routeDirectionsProvider.overrideWith((ref) async => null),
          rideCategoriesProvider.overrideWith((ref) async => <RideCategory>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: BookingFlowListeners(
                onNavigateToSearch: () {},
                onExpandSheet: () {},
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      );

      container.read(selectedRouteIndexProvider.notifier).state = 2;
      container
          .read(selectedDestinationProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: 'google_dest_1',
              name: 'Aeroport',
              address: 'Route de l Aeroport',
              latitude: 5.26,
              longitude: -3.94,
            ),
          );
      await tester.pump();

      expect(container.read(bookingManualRefreshTriggerProvider), 1);
      expect(container.read(selectedRouteIndexProvider), 0);
    },
  );

  testWidgets('pending search timeout dialog can relaunch search', (
    tester,
  ) async {
    _TimeoutBookingFlow.startSearchCalls = 0;
    final container = ProviderContainer(
      overrides: [
        bookingFlowProvider.overrideWith(_TimeoutBookingFlow.new),
        routeDirectionsProvider.overrideWith((ref) async => null),
        rideCategoriesProvider.overrideWith((ref) async => <RideCategory>[]),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: BookingFlowListeners(
              onNavigateToSearch: () {},
              onExpandSheet: () {},
              child: const SizedBox(),
            ),
          ),
        ),
      ),
    );

    container.read(pendingSearchTimeoutEventProvider.notifier).state++;
    await tester.pump();

    expect(find.text('Recherche interrompue'), findsOneWidget);
    expect(find.text('Continuer la recherche'), findsOneWidget);
    expect(find.text('Modifier ma destination'), findsOneWidget);
    _expectAbove(
      tester,
      find.text('Modifier ma destination'),
      find.text('Continuer la recherche'),
    );

    await tester.tap(find.text('Continuer la recherche'));
    await tester.pump();

    expect(_TimeoutBookingFlow.startSearchCalls, 1);
    expect(container.read(bookingFlowProvider), BookingFlowState.searching);
  });

  testWidgets('active ride cancellation event navigates to home callback', (
    tester,
  ) async {
    var navigateCalls = 0;
    final container = ProviderContainer(
      overrides: [
        bookingFlowProvider.overrideWith(_RoutePreviewBookingFlow.new),
        routeDirectionsProvider.overrideWith((ref) async => null),
        rideCategoriesProvider.overrideWith((ref) async => <RideCategory>[]),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: BookingFlowListeners(
              onNavigateToSearch: () => navigateCalls++,
              onExpandSheet: () {},
              child: const SizedBox(),
            ),
          ),
        ),
      ),
    );

    container
        .read(bookingActiveRideCancelledHomeEventProvider.notifier)
        .state++;
    await tester.pump();

    expect(navigateCalls, 1);
    expect(find.text('Course annulée'), findsNothing);
  });

  testWidgets(
    'remote cancellation shows timed dialog and opens address search',
    (tester) async {
      var navigateCalls = 0;
      var openSearchCalls = 0;
      final soundService = _RecordingCancellationSoundService();
      final container = ProviderContainer(
        overrides: [
          bookingFlowProvider.overrideWith(_RoutePreviewBookingFlow.new),
          routeDirectionsProvider.overrideWith((ref) async => null),
          rideCategoriesProvider.overrideWith((ref) async => <RideCategory>[]),
          passengerRideAlertSoundServiceProvider.overrideWithValue(
            soundService,
          ),
          passengerSettingsProvider.overrideWith(
            (ref) => _TestPassengerSettingsNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: BookingFlowListeners(
                onNavigateToSearch: () => navigateCalls++,
                onOpenDestinationSearch: () => openSearchCalls++,
                onExpandSheet: () {},
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      );

      container.read(bookingRemoteRideCancelledEventProvider.notifier).state++;
      await tester.pump();

      expect(find.text('Course annulée'), findsOneWidget);
      expect(find.text('Votre chauffeur a annulé la course.'), findsOneWidget);
      expect(find.text('Redirection automatique dans 10 s'), findsOneWidget);
      expect(find.byType(ConfirmationActionColumn), findsOneWidget);
      expect(find.text('Rechercher un chauffeur'), findsOneWidget);
      expect(find.text("Revenir à l'accueil"), findsOneWidget);
      _expectAbove(
        tester,
        find.text('Rechercher un chauffeur'),
        find.text("Revenir à l'accueil"),
      );
      expect(soundService.cancellationPlayCalls, 1);
      expect(navigateCalls, 0);
      expect(openSearchCalls, 0);

      await tester.tap(find.text("Revenir à l'accueil"));
      await tester.pump();
      await tester.pump();

      expect(find.text('Course annulée'), findsNothing);
      expect(navigateCalls, 1);
      expect(openSearchCalls, 0);

      container.read(bookingRemoteRideCancelledEventProvider.notifier).state++;
      await tester.pump();
      await tester.tap(find.text('Rechercher un chauffeur'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Course annulée'), findsNothing);
      expect(openSearchCalls, 1);
      expect(navigateCalls, 1);

      container.read(bookingRemoteRideCancelledEventProvider.notifier).state++;
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      expect(find.text('Course annulée'), findsNothing);
      expect(openSearchCalls, 2);
      expect(navigateCalls, 1);
      expect(soundService.cancellationPlayCalls, 3);
    },
  );

  testWidgets(
    'active ride conflict dialog keeps secondary action below primary',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          bookingFlowProvider.overrideWith(_ConflictBookingFlow.new),
          routeDirectionsProvider.overrideWith((ref) async => null),
          rideCategoriesProvider.overrideWith((ref) async => <RideCategory>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: BookingFlowListeners(
                onNavigateToSearch: () {},
                onExpandSheet: () {},
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      );

      final notifier = container.read(bookingFlowProvider.notifier);
      (notifier as _ConflictBookingFlow).triggerConflict();
      await tester.pumpAndSettle();

      expect(find.text('Course en cours'), findsOneWidget);
      _expectAbove(
        tester,
        find.text('Annuler et continuer'),
        find.text('Garder ma course'),
      );

      await tester.tap(find.text('Garder ma course'));
      await tester.pumpAndSettle();

      expect(notifier.resetCalls, 1);
      expect(notifier.cancelExistingAndRetryCalls, 0);
    },
  );

  testWidgets('active ride conflict primary action cancels and retries', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        bookingFlowProvider.overrideWith(_ConflictBookingFlow.new),
        routeDirectionsProvider.overrideWith((ref) async => null),
        rideCategoriesProvider.overrideWith((ref) async => <RideCategory>[]),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: BookingFlowListeners(
              onNavigateToSearch: () {},
              onExpandSheet: () {},
              child: const SizedBox(),
            ),
          ),
        ),
      ),
    );

    final notifier = container.read(bookingFlowProvider.notifier);
    (notifier as _ConflictBookingFlow).triggerConflict();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler et continuer'));
    await tester.pumpAndSettle();

    expect(notifier.cancelExistingAndRetryCalls, 1);
    expect(notifier.resetCalls, 0);
  });

  testWidgets('pricing error is shown with modify destination action', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        bookingFlowProvider.overrideWith(_RoutePreviewBookingFlow.new),
        routeDirectionsProvider.overrideWith((ref) async => null),
        rideCategoriesProvider.overrideWith((ref) async => <RideCategory>[]),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: BookingFlowListeners(
              onNavigateToSearch: () {},
              onExpandSheet: () {},
              child: const SizedBox(),
            ),
          ),
        ),
      ),
    );

    container.read(bookingErrorProvider.notifier).state =
        pricingUnavailableMessage;
    await tester.pump();

    expect(find.text(pricingUnavailableMessage), findsOneWidget);
    expect(find.text('Modifier ma destination'), findsOneWidget);
  });
}

class _FakeBookingRepository implements BookingRepository {
  @override
  Future<List<RideCategory>> getRideCategories() async {
    return const [
      RideCategory(
        id: 'MAGIC',
        name: 'Magic',
        description: 'Eco',
        price: 2500,
        seats: 4,
        iconAsset: 'assets/images/magic.png',
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestPassengerAuthNotifier extends PassengerAuthNotifier {
  _TestPassengerAuthNotifier(AuthState initialState)
    : super(
        loginUsecase: LoginPassengerUsecase(PassengerAuthRepository()),
        registerStep1Usecase: RegisterStep1Usecase(PassengerAuthRepository()),
        registerStep2Usecase: RegisterStep2Usecase(PassengerAuthRepository()),
        registerStep3Usecase: RegisterStep3Usecase(PassengerAuthRepository()),
        logoutUsecase: LogoutPassengerUsecase(),
      ) {
    state = initialState;
  }

  @override
  Future<void> logout() async {
    if (!mounted) return;
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

class _RecordingCancellationSoundService
    extends PassengerRideAlertSoundService {
  _RecordingCancellationSoundService() : super.test();

  int cancellationPlayCalls = 0;

  @override
  Future<void> playCancellationAlert() async {
    cancellationPlayCalls++;
  }

  @override
  Future<void> dispose() async {}
}

class _TestPassengerSettingsNotifier extends PassengerSettingsNotifier {
  _TestPassengerSettingsNotifier() : super(PassengerSettingsService()) {
    state = const PassengerSettingsState(soundsEnabled: true);
  }

  @override
  Future<void> load() async {}
}

void _expectAbove(WidgetTester tester, Finder top, Finder bottom) {
  expect(tester.getTopLeft(top).dy, lessThan(tester.getTopLeft(bottom).dy));
}
