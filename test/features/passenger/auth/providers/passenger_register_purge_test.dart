import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/auth_register_draft.dart';
import 'package:fraya_mobile/domain/repositories/auth_register_draft_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/login_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step3_usecase.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/auth_register_flow_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await LocalStorage.instance.init();
  });

  test('step3 completes only after the passenger is authenticated', () async {
    final notifier = _buildNotifier(_PassengerAuthRepository());
    addTearDown(notifier.dispose);
    await _waitForInitialAuthCheck(notifier);

    await notifier.registerStep3(_registrationPayload);

    expect(notifier.state.status, AuthStatus.authenticated);
    expect(notifier.state.userData?['id'], 42);
  });

  test(
    'successful passenger registration clears draft and flow state',
    () async {
      final notifier = _buildNotifier(_PassengerAuthRepository());
      final draftRepository = _DraftRepository();
      final controller = _buildController(notifier, draftRepository);
      addTearDown(notifier.dispose);
      addTearDown(controller.dispose);
      await _waitForInitialAuthCheck(notifier);
      _fillRegistration(controller);

      await controller.completeRegistration(password: 'secret123');

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(draftRepository.draft, isNull);
      expect(controller.state.currentStep, AuthRegisterFlowStep.contact);
      expect(controller.state.phoneNumber, isNull);
      expect(controller.state.firstNames, isNull);
      expect(
        await LocalStorage.instance.getSecure(AppConstants.accessTokenKey),
        'passenger-token',
      );
    },
  );

  test('failed passenger registration keeps the draft', () async {
    final notifier = _buildNotifier(_PassengerAuthRepository(success: false));
    final draftRepository = _DraftRepository();
    final controller = _buildController(notifier, draftRepository);
    addTearDown(notifier.dispose);
    addTearDown(controller.dispose);
    await _waitForInitialAuthCheck(notifier);
    _fillRegistration(controller);

    await controller.completeRegistration(password: 'secret123');

    expect(notifier.state.status, AuthStatus.error);
    expect(draftRepository.draft?.step, AuthRegisterFlowStep.details);
    expect(controller.state.phoneNumber, '0700000000');
  });
}

const _registrationPayload = <String, dynamic>{
  'phoneNumber': '0700000000',
  'firstNames': 'Awa',
  'lastName': 'Kouassi',
  'password': 'secret123',
  'genre': 'FEMININ',
  'userRegistrationType': 'USER',
};

PassengerAuthNotifier _buildNotifier(PassengerAuthRepository repository) {
  return PassengerAuthNotifier(
    loginUsecase: LoginPassengerUsecase(repository),
    registerStep1Usecase: RegisterStep1Usecase(repository),
    registerStep2Usecase: RegisterStep2Usecase(repository),
    registerStep3Usecase: RegisterStep3Usecase(repository),
    logoutUsecase: LogoutPassengerUsecase(),
  );
}

AuthRegisterFlowController _buildController(
  PassengerAuthNotifier notifier,
  _DraftRepository draftRepository,
) {
  return AuthRegisterFlowController(
    role: AuthRegisterRole.passenger,
    userRegistrationType: 'USER',
    draftRepository: draftRepository,
    sendOtpAction: notifier.registerStep1,
    verifyOtpAction: notifier.registerStep2,
    completeRegistrationAction: notifier.registerStep3,
    isAuthenticated: () => notifier.state.status == AuthStatus.authenticated,
  );
}

void _fillRegistration(AuthRegisterFlowController controller) {
  controller.updateDraftFields(
    phoneNumber: '0700000000',
    email: '',
    firstNames: 'Awa',
    lastName: 'Kouassi',
    genre: 'FEMININ',
  );
}

Future<void> _waitForInitialAuthCheck(PassengerAuthNotifier notifier) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (notifier.state.status != AuthStatus.idle) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Passenger auth initialization did not complete.');
}

class _PassengerAuthRepository extends PassengerAuthRepository {
  _PassengerAuthRepository({this.success = true});

  final bool success;

  @override
  Future<Map<String, dynamic>> registerStep3(
    Map<String, dynamic> userData,
  ) async {
    if (!success) {
      return {'success': false, 'message': 'Inscription refusée'};
    }
    return {
      'success': true,
      'data': {
        'access_token': 'passenger-token',
        'user': {'id': 42, 'firstNames': 'Awa'},
      },
    };
  }
}

class _DraftRepository implements AuthRegisterDraftRepository {
  AuthRegisterDraft? draft;

  @override
  Future<AuthRegisterDraft?> readDraft(AuthRegisterRole role) async => draft;

  @override
  Future<void> saveDraft(AuthRegisterDraft value) async => draft = value;

  @override
  Future<void> clearDraft(AuthRegisterRole role) async => draft = null;
}
