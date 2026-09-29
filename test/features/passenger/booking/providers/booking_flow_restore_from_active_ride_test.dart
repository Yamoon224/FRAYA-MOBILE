import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
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
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_route_refresh_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/payment_method_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/pending_search_session_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_categories_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/route_directions_provider.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';

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

  test('restoreFromActiveRide clears pickup and destination fields', () {
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
      ],
    );
    addTearDown(container.dispose);

    const ride = ActiveRide(
      rideId: 'ride_123',
      driverName: 'Jean',
      driverPhoto: 'assets/images/driver_placeholder.png',
      driverRating: 4.8,
      carModel: 'Toyota Corolla',
      carPlate: 'AA-123-BB',
      pickupPlaceId: 'pickup_place_123',
      destinationPlaceId: 'destination_place_456',
      pickupAddress: 'Cocody, Angre',
      destinationAddress: 'Plateau, Avenue Chardy',
      driverLocation: _driverLocation,
      pickupLocation: _pickupLocation,
      destinationLocation: _destinationLocation,
      status: _acceptedStatus,
      estimatedPrice: 3000,
    );

    container.read(bookingFlowProvider.notifier).restoreFromActiveRide(ride);

    expect(container.read(selectedPickupProvider), isNull);
    expect(container.read(selectedDestinationProvider), isNull);
    expect(container.read(bookingManualRefreshTriggerProvider), 0);
  });

  test('restoreFromActiveRide restores pending rides as searching', () {
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
      ],
    );
    addTearDown(container.dispose);

    const ride = ActiveRide(
      rideId: 'ride_pending_123',
      driverName: 'Recherche chauffeur',
      driverPhoto: 'assets/images/driver_placeholder.png',
      driverRating: 4.8,
      carModel: 'Toyota Corolla',
      carPlate: 'AA-123-BB',
      destinationPlaceId: 'destination_place_456',
      destinationAddress: 'Plateau, Avenue Chardy',
      driverLocation: _driverLocation,
      destinationLocation: _destinationLocation,
      status: RideStatus.pending,
      estimatedPrice: 3000,
    );

    container.read(bookingFlowProvider.notifier).restoreFromActiveRide(ride);

    expect(container.read(bookingFlowProvider), BookingFlowState.searching);
    expect(LocalStorage.instance.getString('active_ride_id'), isNull);
    expect(
      LocalStorage.instance.getString('pending_search_ride_id'),
      'ride_pending_123',
    );
  });

  test(
    'startSearching persists pending search session before assignment',
    () async {
      final repository = _FakeBookingRepository(
        requestRideResult: 'ride_pending_456',
        activeRideResult: const ActiveRide(
          rideId: 'ride_pending_456',
          driverName: 'Recherche chauffeur',
          driverPhoto: 'assets/images/driver_placeholder.png',
          driverRating: 4.8,
          carModel: 'Toyota Corolla',
          carPlate: 'AA-123-BB',
          destinationPlaceId: 'destination_place_456',
          destinationAddress: 'Plateau, Avenue Chardy',
          driverLocation: _driverLocation,
          destinationLocation: _destinationLocation,
          status: RideStatus.pending,
          estimatedPrice: 3000,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          passengerAuthProvider.overrideWith(
            (ref) => _TestPassengerAuthNotifier(
              AuthState(status: AuthStatus.authenticated, userData: {'id': 7}),
            ),
          ),
          activeRideCheckProvider.overrideWith((ref) async => null),
          passengerBookingRepositoryProvider.overrideWithValue(repository),
          formattedAddressProvider.overrideWith((ref) => 'Cocody, Angre'),
          routeDirectionsProvider.overrideWith((ref) async => null),
          currentLocationProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(selectedDestinationProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: 'destination_place_456',
              name: 'Plateau',
              address: 'Plateau, Avenue Chardy',
              latitude: 5.32,
              longitude: -4.00,
            ),
          );
      container
          .read(bookingOriginSnapshotProvider.notifier)
          .state = BookingOriginSnapshot(
        latitude: 5.36,
        longitude: -4.02,
        capturedAt: DateTime(2026, 6, 2),
      );
      container.read(selectedCategoryProvider.notifier).select(_magicCategory);
      container.read(selectedPaymentMethodProvider.notifier).state =
          PaymentMethod.cash;

      await container.read(bookingFlowProvider.notifier).startSearching();

      expect(LocalStorage.instance.getString('active_ride_id'), isNull);
      expect(
        LocalStorage.instance.getString('pending_search_ride_id'),
        'ride_pending_456',
      );
      expect(
        LocalStorage.instance.getInt('pending_search_started_at_ms'),
        isNotNull,
      );
      expect(container.read(bookingFlowProvider), BookingFlowState.searching);
      container.read(bookingFlowProvider.notifier).reset();
    },
  );

  test(
    'accepted ride clears pending search session and persists active ride',
    () async {
      final repository = _FakeBookingRepository(
        requestRideResult: 'ride_accepted_456',
        activeRideResult: const ActiveRide(
          rideId: 'ride_accepted_456',
          driverName: 'Jean',
          driverPhoto: 'assets/images/driver_placeholder.png',
          driverRating: 4.8,
          carModel: 'Toyota Corolla',
          carPlate: 'AA-123-BB',
          destinationPlaceId: 'destination_place_456',
          destinationAddress: 'Plateau, Avenue Chardy',
          driverLocation: _driverLocation,
          destinationLocation: _destinationLocation,
          status: RideStatus.accepted,
          estimatedPrice: 3000,
        ),
      );
      final container = _createStartSearchContainer(repository);
      addTearDown(container.dispose);
      _seedSearchInputs(container);

      await container.read(bookingFlowProvider.notifier).startSearching();

      expect(LocalStorage.instance.getString('pending_search_ride_id'), isNull);
      expect(
        LocalStorage.instance.getString('active_ride_id'),
        'ride_accepted_456',
      );
      expect(
        container.read(bookingFlowProvider),
        BookingFlowState.driverAssigned,
      );
      container.read(bookingFlowProvider.notifier).reset();
    },
  );

  test('pending search timeout cancels ride and emits timeout event', () async {
    final repository = _FakeBookingRepository(
      requestRideResult: 'ride_pending_timeout',
      activeRideResult: const ActiveRide(
        rideId: 'ride_pending_timeout',
        driverName: 'Recherche chauffeur',
        driverPhoto: 'assets/images/driver_placeholder.png',
        driverRating: 4.8,
        carModel: 'Toyota Corolla',
        carPlate: 'AA-123-BB',
        destinationPlaceId: 'destination_place_456',
        destinationAddress: 'Plateau, Avenue Chardy',
        driverLocation: _driverLocation,
        destinationLocation: _destinationLocation,
        status: RideStatus.pending,
        estimatedPrice: 3000,
      ),
    );
    final container = _createStartSearchContainer(
      repository,
      timeout: const Duration(milliseconds: 10),
    );
    addTearDown(container.dispose);
    _seedSearchInputs(container);

    await container.read(bookingFlowProvider.notifier).startSearching();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(repository.cancelRideCalls, 1);
    expect(repository.lastCancelReason, 'Recherche expiree');
    expect(container.read(bookingFlowProvider), BookingFlowState.routePreview);
    expect(container.read(pendingSearchTimeoutEventProvider), 1);
    expect(LocalStorage.instance.getString('pending_search_ride_id'), isNull);
  });

  test(
    'cancelSearching on pending ride keeps route preview without home event',
    () async {
      final repository = _FakeBookingRepository();
      final container = _createStartSearchContainer(repository);
      addTearDown(container.dispose);
      container
          .read(activeRideControllerProvider.notifier)
          .initialize(ActiveRide.mock.copyWith(status: RideStatus.pending));

      await container
          .read(bookingFlowProvider.notifier)
          .cancelSearching(reason: 'Recherche annulee');

      expect(repository.cancelRideCalls, 1);
      expect(
        container.read(bookingFlowProvider),
        BookingFlowState.routePreview,
      );
      expect(container.read(bookingActiveRideCancelledHomeEventProvider), 0);
    },
  );

  test('cancelSearching on accepted ride emits home event', () async {
    final repository = _FakeBookingRepository();
    final container = _createStartSearchContainer(repository);
    addTearDown(container.dispose);
    container
        .read(activeRideControllerProvider.notifier)
        .initialize(ActiveRide.mock.copyWith(status: RideStatus.accepted));

    await container
        .read(bookingFlowProvider.notifier)
        .cancelSearching(reason: 'Course annulee');

    expect(repository.cancelRideCalls, 1);
    expect(container.read(bookingFlowProvider), BookingFlowState.idle);
    expect(container.read(activeRideControllerProvider), isNull);
    expect(container.read(bookingActiveRideCancelledHomeEventProvider), 1);
  });

  test(
    'cancelSearching refuses cancellation once driver has arrived',
    () async {
      final repository = _FakeBookingRepository();
      final container = _createStartSearchContainer(repository);
      addTearDown(container.dispose);
      container
          .read(activeRideControllerProvider.notifier)
          .initialize(ActiveRide.mock.copyWith(status: RideStatus.arrived));

      await container
          .read(bookingFlowProvider.notifier)
          .cancelSearching(reason: 'Trop tard');

      expect(repository.cancelRideCalls, 0);
      expect(
        container.read(bookingErrorProvider),
        'La course ne peut plus être annulée car le chauffeur est déjà arrivé.',
      );
    },
  );
}

const _driverLocation = LatLng(5.35, -4.01);
const _pickupLocation = LatLng(5.36, -4.02);
const _destinationLocation = LatLng(5.32, -4.00);
const _acceptedStatus = RideStatus.accepted;
const _magicCategory = RideCategory(
  id: 'MAGIC',
  name: 'Magic',
  description: 'Eco',
  price: 2500,
  seats: 4,
  iconAsset: 'assets/images/magic.png',
);

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({this.requestRideResult = '', this.activeRideResult});

  final String requestRideResult;
  final ActiveRide? activeRideResult;
  int cancelRideCalls = 0;
  String? lastCancelReason;

  @override
  Future<String> requestRide(RequestRideParams params) async =>
      requestRideResult;

  @override
  Future<ActiveRide?> getActiveRide(int userId, {String? rideId}) async {
    return activeRideResult;
  }

  @override
  Future<bool> cancelRide(String rideId, {String? reason}) async {
    cancelRideCalls++;
    lastCancelReason = reason;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _createStartSearchContainer(
  _FakeBookingRepository repository, {
  Duration? timeout,
}) {
  return ProviderContainer(
    overrides: [
      passengerAuthProvider.overrideWith(
        (ref) => _TestPassengerAuthNotifier(
          AuthState(status: AuthStatus.authenticated, userData: {'id': 7}),
        ),
      ),
      activeRideCheckProvider.overrideWith((ref) async => null),
      passengerBookingRepositoryProvider.overrideWithValue(repository),
      formattedAddressProvider.overrideWith((ref) => 'Cocody, Angre'),
      routeDirectionsProvider.overrideWith((ref) async => null),
      currentLocationProvider.overrideWith((ref) => const Stream.empty()),
      if (timeout != null)
        pendingSearchTimeoutProvider.overrideWith((ref) => timeout),
    ],
  );
}

void _seedSearchInputs(ProviderContainer container) {
  container
      .read(selectedDestinationProvider.notifier)
      .setPlace(
        const PlaceDetails(
          placeId: 'destination_place_456',
          name: 'Plateau',
          address: 'Plateau, Avenue Chardy',
          latitude: 5.32,
          longitude: -4.00,
        ),
      );
  container
      .read(bookingOriginSnapshotProvider.notifier)
      .state = BookingOriginSnapshot(
    latitude: 5.36,
    longitude: -4.02,
    capturedAt: DateTime(2026, 6, 2),
  );
  container.read(selectedCategoryProvider.notifier).select(_magicCategory);
  container.read(selectedPaymentMethodProvider.notifier).state =
      PaymentMethod.cash;
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
