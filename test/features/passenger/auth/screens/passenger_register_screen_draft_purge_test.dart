import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/auth_register_draft.dart';
import 'package:fraya_mobile/domain/repositories/auth_register_draft_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/login_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step3_usecase.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_register_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';
import 'package:fraya_mobile/features/passenger/auth/screens/passenger_register_screen.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/auth_register_flow_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.instance.init();
  });

  testWidgets('clears visible contact fields after registration purge', (
    tester,
  ) async {
    final draftRepository = _DraftRepositoryFake();
    var authenticated = false;
    final flowController = AuthRegisterFlowController(
      role: AuthRegisterRole.passenger,
      userRegistrationType: 'USER',
      draftRepository: draftRepository,
      sendOtpAction: (phoneNumber, {email}) async {},
      verifyOtpAction: (phoneNumber, verificationCode) async {},
      completeRegistrationAction: (_) async => authenticated = true,
      isAuthenticated: () => authenticated,
    );
    final authNotifier = _PassengerAuthNotifierFake(
      AuthState(status: AuthStatus.unauthenticated),
    );
    final container = ProviderContainer(
      overrides: [
        passengerRegisterFlowProvider.overrideWith((ref) => flowController),
        passengerAuthProvider.overrideWith((ref) => authNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PassengerRegisterScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), '0700000000');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'client@example.com',
    );
    expect(_fieldText(tester, 0), '0700000000');
    expect(_fieldText(tester, 1), 'client@example.com');

    await flowController.completeRegistration(password: 'secret123');
    await tester.pump();

    expect(_fieldText(tester, 0), isEmpty);
    expect(_fieldText(tester, 1), isEmpty);
    expect(draftRepository.drafts[AuthRegisterRole.passenger], isNull);
  });
}

String _fieldText(WidgetTester tester, int index) {
  return tester
      .widget<EditableText>(find.byType(EditableText).at(index))
      .controller
      .text;
}

class _DraftRepositoryFake implements AuthRegisterDraftRepository {
  final drafts = <AuthRegisterRole, AuthRegisterDraft>{};

  @override
  Future<AuthRegisterDraft?> readDraft(AuthRegisterRole role) async {
    return drafts[role];
  }

  @override
  Future<void> saveDraft(AuthRegisterDraft draft) async {
    drafts[draft.role] = draft;
  }

  @override
  Future<void> clearDraft(AuthRegisterRole role) async {
    drafts.remove(role);
  }
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
