import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/auth_register_draft.dart';
import 'package:fraya_mobile/domain/repositories/auth_register_draft_repository.dart';
import 'package:fraya_mobile/shared/providers/auth_register_flow_controller.dart';

void main() {
  group('AuthRegisterFlowController', () {
    test('restores draft fields and step', () async {
      final repository = _FakeDraftRepository()
        ..drafts[AuthRegisterRole.passenger] = AuthRegisterDraft(
          role: AuthRegisterRole.passenger,
          step: AuthRegisterFlowStep.details,
          phoneNumber: '0700000000',
          email: 'client@example.com',
          firstNames: 'Jean',
          lastName: 'Kouassi',
          genre: 'MASCULIN',
          updatedAt: DateTime(2026),
        );
      final controller = _controller(repository: repository);
      addTearDown(controller.dispose);

      await controller.restoreDraft();

      expect(controller.state.currentStep, AuthRegisterFlowStep.details);
      expect(controller.state.phoneNumber, '0700000000');
      expect(controller.state.email, 'client@example.com');
      expect(controller.state.firstNames, 'Jean');
      expect(controller.state.lastName, 'Kouassi');
      expect(controller.state.genre, 'MASCULIN');
    });

    test('sendOtp saves contact then moves to otp with cooldown', () async {
      final repository = _FakeDraftRepository();
      var step1Calls = 0;
      final controller = _controller(
        repository: repository,
        sendOtpAction: (phoneNumber, {email}) async {
          step1Calls++;
          expect(phoneNumber, '0700000000');
          expect(email, 'client@example.com');
        },
      );
      addTearDown(controller.dispose);
      controller.updateDraftFields(
        phoneNumber: '0700000000',
        email: 'client@example.com',
        firstNames: '',
        lastName: '',
        genre: null,
      );

      await controller.sendOtp();

      expect(step1Calls, 1);
      expect(controller.state.currentStep, AuthRegisterFlowStep.otp);
      expect(controller.state.otpResendSecondsRemaining, 30);
      expect(repository.savedDrafts.last.step, AuthRegisterFlowStep.otp);
    });

    test('resendOtp is blocked while cooldown is active', () async {
      final repository = _FakeDraftRepository();
      var step1Calls = 0;
      final controller = _controller(
        repository: repository,
        sendOtpAction: (phoneNumber, {email}) async => step1Calls++,
      );
      addTearDown(controller.dispose);
      controller.updateDraftFields(
        phoneNumber: '0700000000',
        email: '',
        firstNames: '',
        lastName: '',
        genre: null,
      );

      await controller.sendOtp();
      await controller.resendOtp();

      expect(step1Calls, 1);
    });

    testWidgets('otp cooldown reaches zero after 30 seconds', (tester) async {
      final controller = _controller(repository: _FakeDraftRepository());
      addTearDown(controller.dispose);
      controller.updateDraftFields(
        phoneNumber: '0700000000',
        email: '',
        firstNames: '',
        lastName: '',
        genre: null,
      );

      await controller.sendOtp();
      expect(controller.state.otpResendSecondsRemaining, 30);

      await tester.pump(const Duration(seconds: 30));

      expect(controller.state.otpResendSecondsRemaining, 0);
    });

    test(
      'completeRegistration sends payload then clears draft on success',
      () async {
        final repository = _FakeDraftRepository();
        Map<String, dynamic>? payload;
        var authenticated = false;
        final controller = _controller(
          repository: repository,
          completeRegistrationAction: (data) async {
            payload = data;
            authenticated = true;
          },
          isAuthenticated: () => authenticated,
        );
        addTearDown(controller.dispose);
        controller.updateDraftFields(
          phoneNumber: '0700000000',
          email: 'client@example.com',
          firstNames: 'Jean',
          lastName: 'Kouassi',
          genre: 'MASCULIN',
        );

        await controller.completeRegistration(password: 'secret123');

        expect(payload, {
          'firstNames': 'Jean',
          'lastName': 'Kouassi',
          'email': 'client@example.com',
          'phoneNumber': '0700000000',
          'password': 'secret123',
          'genre': 'MASCULIN',
          'userRegistrationType': 'USER',
        });
        expect(repository.clearedRoles, [AuthRegisterRole.passenger]);
        expect(repository.drafts[AuthRegisterRole.passenger], isNull);
        _expectEmptyState(controller.state);
      },
    );

    testWidgets(
      'success purge prevents pending debounce from recreating draft',
      (tester) async {
        final repository = _FakeDraftRepository();
        var authenticated = false;
        final controller = _controller(
          repository: repository,
          completeRegistrationAction: (_) async => authenticated = true,
          isAuthenticated: () => authenticated,
        );
        addTearDown(controller.dispose);
        controller.updateDraftFields(
          phoneNumber: '0700000000',
          email: 'client@example.com',
          firstNames: 'Jean',
          lastName: 'Kouassi',
          genre: 'MASCULIN',
        );

        await controller.completeRegistration(password: 'secret123');
        await tester.pump(const Duration(milliseconds: 400));

        expect(repository.drafts[AuthRegisterRole.passenger], isNull);
        expect(repository.savedDrafts, hasLength(1));
        _expectEmptyState(controller.state);
      },
    );

    test(
      'completeRegistration keeps draft when step3 does not authenticate',
      () async {
        final repository = _FakeDraftRepository();
        final controller = _controller(
          repository: repository,
          completeRegistrationAction: (_) async {},
          isAuthenticated: () => false,
        );
        addTearDown(controller.dispose);
        controller.updateDraftFields(
          phoneNumber: '0700000000',
          email: 'client@example.com',
          firstNames: 'Jean',
          lastName: 'Kouassi',
          genre: 'MASCULIN',
        );

        await controller.completeRegistration(password: 'secret123');

        expect(repository.clearedRoles, isEmpty);
        expect(
          repository.drafts[AuthRegisterRole.passenger]?.step,
          AuthRegisterFlowStep.details,
        );
        expect(controller.state.phoneNumber, '0700000000');
      },
    );

    test('sendOtp error stays on contact and keeps draft', () async {
      final repository = _FakeDraftRepository();
      final controller = _controller(
        repository: repository,
        sendOtpAction: (phoneNumber, {email}) async {
          throw Exception('step1 failed');
        },
      );
      addTearDown(controller.dispose);
      controller.updateDraftFields(
        phoneNumber: '0700000000',
        email: '',
        firstNames: '',
        lastName: '',
        genre: null,
      );

      await controller.sendOtp();

      expect(controller.state.currentStep, AuthRegisterFlowStep.contact);
      expect(repository.savedDrafts.last.step, AuthRegisterFlowStep.contact);
    });
  });
}

void _expectEmptyState(AuthRegisterFlowState state) {
  expect(state.currentStep, AuthRegisterFlowStep.contact);
  expect(state.phoneNumber, isNull);
  expect(state.email, isNull);
  expect(state.firstNames, isNull);
  expect(state.lastName, isNull);
  expect(state.genre, isNull);
  expect(state.otpResendSecondsRemaining, 0);
  expect(state.isResendingOtp, isFalse);
  expect(state.isRestoringDraft, isFalse);
}

AuthRegisterFlowController _controller({
  required _FakeDraftRepository repository,
  AuthRegisterStep1Action? sendOtpAction,
  AuthRegisterStep2Action? verifyOtpAction,
  AuthRegisterCompleteAction? completeRegistrationAction,
  AuthRegisterSuccessReader? isAuthenticated,
}) {
  return AuthRegisterFlowController(
    role: AuthRegisterRole.passenger,
    userRegistrationType: 'USER',
    draftRepository: repository,
    sendOtpAction: sendOtpAction ?? (phoneNumber, {email}) async {},
    verifyOtpAction:
        verifyOtpAction ?? (phoneNumber, verificationCode) async {},
    completeRegistrationAction:
        completeRegistrationAction ?? (payload) async {},
    isAuthenticated: isAuthenticated ?? () => false,
  );
}

class _FakeDraftRepository implements AuthRegisterDraftRepository {
  final drafts = <AuthRegisterRole, AuthRegisterDraft>{};
  final savedDrafts = <AuthRegisterDraft>[];
  final clearedRoles = <AuthRegisterRole>[];

  @override
  Future<AuthRegisterDraft?> readDraft(AuthRegisterRole role) async {
    return drafts[role];
  }

  @override
  Future<void> saveDraft(AuthRegisterDraft draft) async {
    savedDrafts.add(draft);
    drafts[draft.role] = draft;
  }

  @override
  Future<void> clearDraft(AuthRegisterRole role) async {
    clearedRoles.add(role);
    drafts.remove(role);
  }
}
