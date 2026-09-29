import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/login_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step3_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/create_sos_alert.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/sos_alert_controller.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'passenger-token',
      'auth_user_data': '{"id":7}',
    });
  });

  test('submit forwards user id, GPS and notes to the use case', () async {
    final repository = _FakeBookingRepository();
    final container = ProviderContainer(
      overrides: [
        createSosAlertUseCaseProvider.overrideWithValue(
          CreateSosAlertUseCase(repository),
        ),
        passengerAuthProvider.overrideWith(
          (ref) => _TestPassengerAuthNotifier(
            AuthState(
              status: AuthStatus.authenticated,
              userData: {'id': 7},
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(sosAlertControllerProvider.notifier)
        .submit(
          rideId: 'ride-77',
          lat: 5.34,
          lng: -4.02,
          reason: 'Je me sens en danger',
        );

    expect(success, isTrue);
    expect(repository.lastRideId, 'ride-77');
    expect(repository.lastUserId, 7);
    expect(repository.lastLat, 5.34);
    expect(repository.lastLng, -4.02);
    expect(repository.lastNotes, 'Je me sens en danger');
  });

  test('submit falls back to zero coordinates and prefixes the note when GPS is missing', () async {
    final repository = _FakeBookingRepository();
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'passenger-token',
      'auth_user_data': '{"id":9}',
    });
    final container = ProviderContainer(
      overrides: [
        createSosAlertUseCaseProvider.overrideWithValue(
          CreateSosAlertUseCase(repository),
        ),
        passengerAuthProvider.overrideWith(
          (ref) => _TestPassengerAuthNotifier(
            AuthState(
              status: AuthStatus.authenticated,
              userData: {'id': 9},
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(sosAlertControllerProvider.notifier)
        .submit(
          rideId: 'ride-90',
          reason: 'Accident ou incident',
        );

    expect(success, isTrue);
    expect(repository.lastUserId, 9);
    expect(repository.lastLat, 0);
    expect(repository.lastLng, 0);
    expect(repository.lastNotes, 'GPS indisponible - Accident ou incident');
  });

  test('submit exposes a readable error when no authenticated user is available', () async {
    final repository = _FakeBookingRepository();
    FlutterSecureStorage.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        createSosAlertUseCaseProvider.overrideWithValue(
          CreateSosAlertUseCase(repository),
        ),
        passengerAuthProvider.overrideWith(
          (ref) => _TestPassengerAuthNotifier(
            AuthState(status: AuthStatus.unauthenticated),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(sosAlertControllerProvider.notifier)
        .submit(rideId: 'ride-91', reason: 'Autre urgence');

    expect(success, isFalse);
    expect(repository.lastRideId, isNull);
    expect(
      container.read(sosAlertControllerProvider).errorMessage,
      'Utilisateur introuvable.',
    );
  });
}

class _FakeBookingRepository implements BookingRepository {
  String? lastRideId;
  int? lastUserId;
  double? lastLat;
  double? lastLng;
  String? lastNotes;

  @override
  Future<bool> triggerSos({
    required String rideId,
    required int userId,
    required double lat,
    required double lng,
    String? notes,
  }) async {
    lastRideId = rideId;
    lastUserId = userId;
    lastLat = lat;
    lastLng = lng;
    lastNotes = notes;
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
}
