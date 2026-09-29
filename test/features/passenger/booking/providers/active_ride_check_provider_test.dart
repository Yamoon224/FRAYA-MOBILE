import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:fraya_mobile/shared/models/auth_state.dart';

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

  test('activeRideCheckProvider skips authenticated pending rides', () async {
    await LocalStorage.instance.setString('active_ride_id', 'ride_pending_1');
    final repository = _FakeBookingRepository(
      activeRideResult: const ActiveRide(
        rideId: 'ride_pending_1',
        driverName: 'Recherche chauffeur',
        driverPhoto: 'assets/images/driver_placeholder.png',
        driverRating: 4.8,
        carModel: 'Toyota Corolla',
        carPlate: 'AA-123-BB',
        destinationAddress: 'Plateau, Avenue Chardy',
        driverLocation: LatLng(5.35, -4.01),
        destinationLocation: LatLng(5.32, -4.00),
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
        passengerBookingRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final ride = await container.read(activeRideCheckProvider.future);

    expect(ride, isNull);
    expect(repository.cancelRideCalls, 0);
    expect(LocalStorage.instance.getString('active_ride_id'), 'ride_pending_1');
  });

  test(
    'activeRideCheckProvider restores authenticated accepted rides',
    () async {
      await LocalStorage.instance.setString(
        'active_ride_id',
        'ride_accepted_1',
      );
      final repository = _FakeBookingRepository(
        activeRideResult: const ActiveRide(
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
      );
      final container = ProviderContainer(
        overrides: [
          passengerAuthProvider.overrideWith(
            (ref) => _TestPassengerAuthNotifier(
              AuthState(status: AuthStatus.authenticated, userData: {'id': 7}),
            ),
          ),
          passengerBookingRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final ride = await container.read(activeRideCheckProvider.future);

      expect(ride, isNotNull);
      expect(ride!.rideId, 'ride_accepted_1');
      expect(ride.status, RideStatus.accepted);
      expect(repository.cancelRideCalls, 0);
    },
  );

  test(
    'activeRideCheckProvider stores completed rides for summary and clears active id',
    () async {
      await LocalStorage.instance.setString(
        'active_ride_id',
        'ride_completed_1',
      );
      final repository = _FakeBookingRepository(
        activeRideResult: const ActiveRide(
          rideId: 'ride_completed_1',
          driverName: 'Jean',
          driverPhoto: 'assets/images/driver_placeholder.png',
          driverRating: 4.8,
          carModel: 'Toyota Corolla',
          carPlate: 'AA-123-BB',
          destinationAddress: 'Plateau, Avenue Chardy',
          driverLocation: LatLng(5.35, -4.01),
          destinationLocation: LatLng(5.32, -4.00),
          status: RideStatus.completed,
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
          passengerBookingRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final ride = await container.read(activeRideCheckProvider.future);
      await _flushAsync();

      expect(ride, isNull);
      expect(
        container.read(completedRideControllerProvider)?.rideId,
        'ride_completed_1',
      );
      expect(LocalStorage.instance.getString('active_ride_id'), isNull);
    },
  );

  test('activeRideCheckProvider clears cancelled saved active id', () async {
    await LocalStorage.instance.setString('active_ride_id', 'ride_cancelled_1');
    final repository = _FakeBookingRepository(
      activeRideResult: const ActiveRide(
        rideId: 'ride_cancelled_1',
        driverName: 'Jean',
        driverPhoto: 'assets/images/driver_placeholder.png',
        driverRating: 4.8,
        carModel: 'Toyota Corolla',
        carPlate: 'AA-123-BB',
        destinationAddress: 'Plateau, Avenue Chardy',
        driverLocation: LatLng(5.35, -4.01),
        destinationLocation: LatLng(5.32, -4.00),
        status: RideStatus.cancelled,
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
        passengerBookingRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final ride = await container.read(activeRideCheckProvider.future);
    await _flushAsync();

    expect(ride, isNull);
    expect(container.read(completedRideControllerProvider), isNull);
    expect(LocalStorage.instance.getString('active_ride_id'), isNull);
  });
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({this.activeRideResult});

  final ActiveRide? activeRideResult;
  int cancelRideCalls = 0;

  @override
  Future<ActiveRide?> getActiveRide(int userId, {String? rideId}) async {
    return activeRideResult;
  }

  @override
  Future<bool> cancelRide(String rideId, {String? reason}) async {
    cancelRideCalls++;
    return true;
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
