import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/pending_search_session_provider.dart';
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

  test('startup cleanup cancels pending search session', () async {
    await LocalStorage.instance.setString(
      AppConstants.pendingSearchRideIdKey,
      'ride_pending_1',
    );
    await LocalStorage.instance.setInt(
      AppConstants.pendingSearchStartedAtKey,
      DateTime(2026, 6, 4).millisecondsSinceEpoch,
    );
    final repository = _FakeBookingRepository(activeRideResult: _pendingRide);
    final container = _createContainer(repository);
    addTearDown(container.dispose);

    await container.read(pendingSearchStartupCleanupProvider.future);

    expect(repository.cancelRideCalls, 1);
    expect(repository.lastCancelReason, 'Nettoyage au lancement');
    expect(
      LocalStorage.instance.getString(AppConstants.pendingSearchRideIdKey),
      isNull,
    );
  });

  test('startup cleanup migrates legacy pending active ride id', () async {
    await LocalStorage.instance.setString(
      AppConstants.activeRideIdKey,
      'ride_pending_1',
    );
    final repository = _FakeBookingRepository(activeRideResult: _pendingRide);
    final container = _createContainer(repository);
    addTearDown(container.dispose);

    await container.read(pendingSearchStartupCleanupProvider.future);

    expect(repository.cancelRideCalls, 1);
    expect(
      LocalStorage.instance.getString(AppConstants.activeRideIdKey),
      isNull,
    );
  });

  test(
    'logout cleanup cancels pending search before session removal',
    () async {
      await LocalStorage.instance.setString(
        AppConstants.pendingSearchRideIdKey,
        'ride_pending_1',
      );
      await LocalStorage.instance.setInt(
        AppConstants.pendingSearchStartedAtKey,
        DateTime(2026, 6, 4).millisecondsSinceEpoch,
      );
      final repository = _FakeBookingRepository(activeRideResult: _pendingRide);
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      await container
          .read(pendingSearchCleanupControllerProvider)
          .cancelPendingSearchBeforeLogout();

      expect(repository.cancelRideCalls, 1);
      expect(repository.lastCancelReason, 'D\u00e9connexion passager');
      expect(
        LocalStorage.instance.getString(AppConstants.pendingSearchRideIdKey),
        isNull,
      );
    },
  );
}

const _pendingRide = ActiveRide(
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
);

ProviderContainer _createContainer(_FakeBookingRepository repository) {
  return ProviderContainer(
    overrides: [
      passengerAuthProvider.overrideWith(
        (ref) => _TestPassengerAuthNotifier(
          AuthState(status: AuthStatus.authenticated, userData: {'id': 7}),
        ),
      ),
      passengerBookingRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({this.activeRideResult});

  final ActiveRide? activeRideResult;
  int cancelRideCalls = 0;
  String? lastCancelReason;

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
