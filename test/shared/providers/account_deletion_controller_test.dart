import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_onboarding_draft.dart';
import 'package:fraya_mobile/domain/repositories/driver_auth_repository.dart';
import 'package:fraya_mobile/domain/repositories/account_deletion_repository.dart';
import 'package:fraya_mobile/domain/repositories/driver_onboarding_draft_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/login_driver_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/logout_driver_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/refresh_driver_profile_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/register_driver_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/register_driver_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/register_driver_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/login_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step3_usecase.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_register_flow_provider.dart';
import 'package:fraya_mobile/features/driver/onboarding/providers/driver_onboarding_draft_dependencies.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/account_deletion_controller.dart';
import 'package:fraya_mobile/shared/providers/account_deletion_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.instance.init();
  });

  test('deletePassengerAccount deletes account and logs out', () async {
    final repository = _AccountDeletionRepositoryFake();
    final authNotifier = _PassengerAuthNotifierFake(
      AuthState(status: AuthStatus.authenticated, userData: const {'id': 24}),
    );
    final container = ProviderContainer(
      overrides: [
        accountDeletionRepositoryProvider.overrideWith((ref) => repository),
        passengerAuthProvider.overrideWith((ref) => authNotifier),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(accountDeletionControllerProvider.notifier)
        .deletePassengerAccount();

    expect(success, isTrue);
    expect(repository.deletedUserId, 24);
    expect(authNotifier.logoutCalls, 1);
  });

  test('deleteDriverAccount deletes account and logs out', () async {
    await LocalStorage.instance.setString(
      AppConstants.driverRegisterDraftKey,
      '{"firstNames":"Ancien"}',
    );
    await LocalStorage.instance.setBool('driver_is_online_18', true);
    await LocalStorage.instance.setBool(AppConstants.themeKey, true);
    final repository = _AccountDeletionRepositoryFake();
    final events = <String>[];
    final draftRepository = _DriverOnboardingDraftRepositoryFake(events);
    final authNotifier = _DriverAuthNotifierFake(
      AuthState(
        status: AuthStatus.authenticated,
        userData: const {'sub': '18'},
      ),
      events: events,
    );
    final container = ProviderContainer(
      overrides: [
        accountDeletionRepositoryProvider.overrideWith((ref) => repository),
        driverOnboardingDraftRepositoryProvider.overrideWith(
          (ref) => draftRepository,
        ),
        driverAuthProvider.overrideWith((ref) => authNotifier),
      ],
    );
    addTearDown(container.dispose);
    final registerFlowBefore = container.read(
      driverRegisterFlowProvider.notifier,
    );

    final success = await container
        .read(accountDeletionControllerProvider.notifier)
        .deleteDriverAccount();

    expect(success, isTrue);
    expect(repository.deletedUserId, 18);
    expect(draftRepository.clearCalls, 1);
    expect(authNotifier.logoutCalls, 1);
    expect(events, ['clearDraft', 'logout']);
    expect(
      LocalStorage.instance.getString(AppConstants.driverRegisterDraftKey),
      isNull,
    );
    expect(LocalStorage.instance.getBool('driver_is_online_18'), isNull);
    expect(LocalStorage.instance.getBool(AppConstants.themeKey), isTrue);
    expect(
      container.read(driverRegisterFlowProvider.notifier),
      isNot(same(registerFlowBefore)),
    );
  });

  test('deletePassengerAccount fails when user id is missing', () async {
    final repository = _AccountDeletionRepositoryFake();
    final authNotifier = _PassengerAuthNotifierFake(
      AuthState(status: AuthStatus.authenticated, userData: const {}),
    );
    final container = ProviderContainer(
      overrides: [
        accountDeletionRepositoryProvider.overrideWith((ref) => repository),
        passengerAuthProvider.overrideWith((ref) => authNotifier),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(accountDeletionControllerProvider.notifier)
        .deletePassengerAccount();

    expect(success, isFalse);
    expect(repository.deletedUserId, isNull);
    expect(
      container.read(accountDeletionControllerProvider).errorMessage,
      "Impossible d'identifier le compte à supprimer.",
    );
  });
}

class _AccountDeletionRepositoryFake implements AccountDeletionRepository {
  int? deletedUserId;

  @override
  Future<void> deleteAccount(int userId) async {
    deletedUserId = userId;
  }
}

class _DriverOnboardingDraftRepositoryFake
    implements DriverOnboardingDraftRepository {
  _DriverOnboardingDraftRepositoryFake(this.events);

  final List<String> events;
  int clearCalls = 0;

  @override
  Future<void> clearDraft() async {
    clearCalls++;
    events.add('clearDraft');
  }

  @override
  Future<bool> documentExists(String path) async => false;

  @override
  Future<DriverKycDocumentFile> persistDocument(
    DriverKycDocumentFile file, {
    required String namespace,
  }) async {
    return file;
  }

  @override
  Future<DriverOnboardingDraft?> readDraft() async => null;

  @override
  Future<void> removePersistedDocument(String path) async {}

  @override
  Future<void> saveDraft(DriverOnboardingDraft draft) async {}
}

class _PassengerAuthNotifierFake extends PassengerAuthNotifier {
  _PassengerAuthNotifierFake(AuthState initialState)
    : super(
        loginUsecase: LoginPassengerUsecase(_PassengerAuthRepositoryFake()),
        registerStep1Usecase: RegisterStep1Usecase(
          _PassengerAuthRepositoryFake(),
        ),
        registerStep2Usecase: RegisterStep2Usecase(
          _PassengerAuthRepositoryFake(),
        ),
        registerStep3Usecase: RegisterStep3Usecase(
          _PassengerAuthRepositoryFake(),
        ),
        logoutUsecase: LogoutPassengerUsecase(),
      ) {
    state = initialState;
  }

  int logoutCalls = 0;

  @override
  Future<void> logout() async {
    logoutCalls++;
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

class _DriverAuthNotifierFake extends DriverAuthNotifier {
  _DriverAuthNotifierFake(AuthState initialState, {this.events = const []})
    : super(
        loginUseCase: LoginDriverUseCase(_DriverAuthRepositoryFake()),
        registerUseCase: RegisterDriverUseCase(_DriverAuthRepositoryFake()),
        registerStep1UseCase: RegisterDriverStep1UseCase(
          _DriverAuthRepositoryFake(),
        ),
        registerStep2UseCase: RegisterDriverStep2UseCase(
          _DriverAuthRepositoryFake(),
        ),
        logoutUseCase: LogoutDriverUseCase(),
        refreshProfileUseCase: RefreshDriverProfileUseCase(
          _DriverAuthRepositoryFake(),
        ),
        autoRestore: false,
      ) {
    state = initialState;
  }

  int logoutCalls = 0;
  final List<String> events;

  @override
  Future<void> logout() async {
    logoutCalls++;
    events.add('logout');
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

class _PassengerAuthRepositoryFake extends PassengerAuthRepository {
  @override
  Future<Map<String, dynamic>> login(String phoneNumber, String password) {
    fail('Unexpected passenger login call.');
  }

  @override
  Future<void> registerStep1(String phoneNumber, {String? email}) {
    fail('Unexpected passenger register step 1 call.');
  }

  @override
  Future<void> registerStep2(String phoneNumber, String verificationCode) {
    fail('Unexpected passenger register step 2 call.');
  }

  @override
  Future<Map<String, dynamic>> registerStep3(Map<String, dynamic> userData) {
    fail('Unexpected passenger register step 3 call.');
  }
}

class _DriverAuthRepositoryFake implements DriverAuthRepository {
  @override
  Future<Map<String, dynamic>> fetchProfile() {
    fail('Unexpected driver fetch profile call.');
  }

  @override
  Future<Map<String, dynamic>> login(String phoneNumber, String password) {
    fail('Unexpected driver login call.');
  }

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) {
    fail('Unexpected driver register call.');
  }

  @override
  Future<void> registerStep1(String phoneNumber, {String? email}) {
    fail('Unexpected driver register step 1 call.');
  }

  @override
  Future<void> registerStep2(String phoneNumber, String verificationCode) {
    fail('Unexpected driver register step 2 call.');
  }
}
