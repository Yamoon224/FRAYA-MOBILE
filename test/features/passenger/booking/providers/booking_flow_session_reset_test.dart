import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
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
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
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

  test(
    'logout transition resets booking flow and clears persisted ride state',
    () async {
      final authNotifier = _TestPassengerAuthNotifier(
        AuthState(status: AuthStatus.authenticated, userData: {'id': 7}),
      );
      final container = ProviderContainer(
        overrides: [
          passengerAuthProvider.overrideWith((ref) => authNotifier),
          activeRideCheckProvider.overrideWith((ref) async => null),
          passengerBookingRepositoryProvider.overrideWithValue(
            _FakeBookingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _flushAsync();
      container.read(bookingFlowProvider);
      container
          .read(selectedPickupProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: 'pickup_place_123',
              name: 'Cocody',
              address: 'Cocody, Angre',
              latitude: 5.36,
              longitude: -4.02,
            ),
          );
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
          .read(activeRideControllerProvider.notifier)
          .initialize(_completedRide.copyWith(rideId: 'ride_old'));
      container.read(bookingFlowProvider.notifier).goToRoutePreview();

      await LocalStorage.instance.setString(
        AppConstants.activeRideIdKey,
        'ride_old',
      );
      await LocalStorage.instance.setString(
        AppConstants.pendingSearchRideIdKey,
        'ride_old',
      );
      await LocalStorage.instance.setInt(
        AppConstants.pendingSearchStartedAtKey,
        123,
      );
      await LocalStorage.instance.setString(
        AppConstants.passengerBookingSessionKey,
        '{"rideId":"ride_old","createdAt":0}',
      );

      authNotifier.setState(AuthState(status: AuthStatus.unauthenticated));
      await _flushAsync();

      expect(container.read(bookingFlowProvider), BookingFlowState.idle);
      expect(container.read(activeRideControllerProvider), isNull);
      expect(container.read(completedRideControllerProvider), isNull);
      expect(container.read(selectedPickupProvider), isNull);
      expect(container.read(selectedDestinationProvider), isNull);
      expect(
        LocalStorage.instance.getString(AppConstants.activeRideIdKey),
        isNull,
      );
      expect(
        LocalStorage.instance.getString(AppConstants.pendingSearchRideIdKey),
        isNull,
      );
      expect(
        LocalStorage.instance.getInt(AppConstants.pendingSearchStartedAtKey),
        isNull,
      );
      expect(
        LocalStorage.instance.getString(
          AppConstants.passengerBookingSessionKey,
        ),
        isNull,
      );
    },
  );

  test('completed ride moves from active ride into summary state', () async {
    final repository = _FakeBookingRepository(activeRideResult: _completedRide);
    final container = _createContainer(
      repository: repository,
      authNotifier: _TestPassengerAuthNotifier(
        AuthState(status: AuthStatus.authenticated, userData: {'id': 7}),
      ),
    );
    addTearDown(container.dispose);

    await _flushAsync();
    await container
        .read(bookingFlowProvider.notifier)
        .handleRideAcceptedRealtime(_completedRide.rideId);

    expect(container.read(bookingFlowProvider), BookingFlowState.completed);
    expect(container.read(activeRideControllerProvider), isNull);
    expect(
      container.read(completedRideControllerProvider)?.rideId,
      _completedRide.rideId,
    );
    expect(
      container.read(completedRideControllerProvider)?.driverName,
      _completedRide.driverName,
    );
  });

  test(
    'backend cancelled active ride clears state and emits home event',
    () async {
      var requestCount = 0;
      final acceptedRide = _completedRide.copyWith(
        rideId: 'ride_cancelled_123',
        status: RideStatus.accepted,
      );
      final cancelledRide = acceptedRide.copyWith(status: RideStatus.cancelled);
      final repository = _FakeBookingRepository(
        getActiveRideHandler: (userId, rideId) {
          requestCount++;
          return requestCount == 1 ? acceptedRide : cancelledRide;
        },
      );
      final container = _createContainer(
        repository: repository,
        authNotifier: _TestPassengerAuthNotifier(
          AuthState(status: AuthStatus.authenticated, userData: {'id': 7}),
        ),
      );
      addTearDown(container.dispose);

      await _flushAsync();
      final notifier = container.read(bookingFlowProvider.notifier);
      await notifier.handleRideAcceptedRealtime(acceptedRide.rideId);
      expect(
        container.read(bookingFlowProvider),
        BookingFlowState.driverAssigned,
      );

      await notifier.hardRefreshStatus();

      expect(container.read(bookingFlowProvider), BookingFlowState.idle);
      expect(container.read(activeRideControllerProvider), isNull);
      expect(container.read(completedRideControllerProvider), isNull);
      expect(container.read(bookingActiveRideCancelledHomeEventProvider), 0);
      expect(container.read(bookingRemoteRideCancelledEventProvider), 1);
    },
  );

  test(
    'completed ride does not re-emit completed after backend returns null',
    () async {
      var requestCount = 0;
      final repository = _FakeBookingRepository(
        getActiveRideHandler: (userId, rideId) {
          requestCount++;
          return requestCount == 1 ? _completedRide : null;
        },
      );
      final container = _createContainer(
        repository: repository,
        authNotifier: _TestPassengerAuthNotifier(
          AuthState(status: AuthStatus.authenticated, userData: {'id': 7}),
        ),
      );
      addTearDown(container.dispose);

      await _flushAsync();
      final notifier = container.read(bookingFlowProvider.notifier);
      await notifier.handleRideAcceptedRealtime(_completedRide.rideId);

      expect(container.read(bookingFlowProvider), BookingFlowState.completed);

      notifier.goToRoutePreview();
      await notifier.hardRefreshStatus();

      expect(
        container.read(bookingFlowProvider),
        BookingFlowState.routePreview,
      );
      expect(container.read(activeRideControllerProvider), isNull);
      expect(repository.getActiveRideCalls.length, 2);
      expect(repository.getActiveRideCalls.first.rideId, _completedRide.rideId);
      expect(repository.getActiveRideCalls.last.rideId, isNull);
    },
  );

  test(
    'logout clears previous passenger ride before next passenger realtime refresh',
    () async {
      final authNotifier = _TestPassengerAuthNotifier(
        AuthState(status: AuthStatus.authenticated, userData: {'id': 7}),
      );
      final repository = _FakeBookingRepository(
        getActiveRideHandler: (userId, rideId) {
          if (userId == 7) return _completedRide;
          return null;
        },
      );
      final container = _createContainer(
        repository: repository,
        authNotifier: authNotifier,
      );
      addTearDown(container.dispose);

      await _flushAsync();
      final notifier = container.read(bookingFlowProvider.notifier);
      await notifier.handleRideAcceptedRealtime(_completedRide.rideId);
      expect(container.read(bookingFlowProvider), BookingFlowState.completed);
      expect(container.read(activeRideControllerProvider), isNull);
      expect(
        container.read(completedRideControllerProvider)?.rideId,
        _completedRide.rideId,
      );

      authNotifier.setState(AuthState(status: AuthStatus.unauthenticated));
      await _flushAsync();

      authNotifier.setState(
        AuthState(status: AuthStatus.authenticated, userData: {'id': 8}),
      );
      await _flushAsync();

      notifier.goToRoutePreview();
      await notifier.handleRideAcceptedRealtime(null);

      expect(
        container.read(bookingFlowProvider),
        BookingFlowState.routePreview,
      );
      expect(container.read(activeRideControllerProvider), isNull);
      expect(container.read(completedRideControllerProvider), isNull);
      expect(
        repository.getActiveRideCalls.map((call) => call.userId).toList(),
        [7, 8],
      );
      expect(
        repository.getActiveRideCalls.map((call) => call.rideId).toList(),
        ['ride_completed_123', null],
      );
    },
  );
}

const _completedRide = ActiveRide(
  rideId: 'ride_completed_123',
  driverName: 'Jean',
  driverPhoto: 'assets/images/driver_placeholder.png',
  driverRating: 4.8,
  carModel: 'Toyota Corolla',
  carPlate: 'AA-123-BB',
  pickupPlaceId: 'pickup_place_123',
  destinationPlaceId: 'destination_place_456',
  pickupAddress: 'Cocody, Angre',
  destinationAddress: 'Plateau, Avenue Chardy',
  driverLocation: LatLng(5.35, -4.01),
  pickupLocation: LatLng(5.36, -4.02),
  destinationLocation: LatLng(5.32, -4.00),
  status: RideStatus.completed,
  estimatedPrice: 3000,
);

ProviderContainer _createContainer({
  required _FakeBookingRepository repository,
  required _TestPassengerAuthNotifier authNotifier,
}) {
  return ProviderContainer(
    overrides: [
      passengerAuthProvider.overrideWith((ref) => authNotifier),
      activeRideCheckProvider.overrideWith((ref) async => null),
      passengerBookingRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({this.activeRideResult, this.getActiveRideHandler});

  final ActiveRide? activeRideResult;
  final ActiveRide? Function(int userId, String? rideId)? getActiveRideHandler;
  final List<_GetActiveRideCall> getActiveRideCalls = [];

  @override
  Future<String> requestRide(RequestRideParams params) async => '';

  @override
  Future<ActiveRide?> getActiveRide(int userId, {String? rideId}) async {
    getActiveRideCalls.add(_GetActiveRideCall(userId: userId, rideId: rideId));
    return getActiveRideHandler?.call(userId, rideId) ?? activeRideResult;
  }

  @override
  Future<bool> cancelRide(String rideId, {String? reason}) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GetActiveRideCall {
  const _GetActiveRideCall({required this.userId, required this.rideId});

  final int userId;
  final String? rideId;
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
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

  void setState(AuthState nextState) {
    if (!mounted) return;
    state = nextState;
  }
}
