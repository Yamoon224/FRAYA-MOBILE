import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/auth_register_draft.dart';
import 'package:fraya_mobile/domain/repositories/auth_register_draft_repository.dart';
import 'package:fraya_mobile/shared/providers/auth_register_flow_controller.dart';

void main() {
  group('AuthRegisterFlowController compound names', () {
    test('preserves spaces while names are being typed', () {
      final controller = _controller(_DraftRepository());
      addTearDown(controller.dispose);

      controller.updateDraftFields(
        phoneNumber: '0700000000',
        email: '',
        firstNames: 'Jean ',
        lastName: 'Kouassi ',
        genre: null,
      );

      expect(controller.state.firstNames, 'Jean ');
      expect(controller.state.lastName, 'Kouassi ');

      controller.updateDraftFields(
        phoneNumber: '0700000000',
        email: '',
        firstNames: 'Jean Marc',
        lastName: 'Kouassi Yao',
        genre: null,
      );

      expect(controller.state.firstNames, 'Jean Marc');
      expect(controller.state.lastName, 'Kouassi Yao');
    });

    test(
      'normalizes names only when building the registration payload',
      () async {
        Map<String, dynamic>? payload;
        final controller = _controller(
          _DraftRepository(),
          completeRegistrationAction: (value) async => payload = value,
        );
        addTearDown(controller.dispose);

        controller.updateDraftFields(
          phoneNumber: '0700000000',
          email: '',
          firstNames: '  Jean  Marc  ',
          lastName: '  Kouassi Yao  ',
          genre: 'MASCULIN',
        );
        await controller.completeRegistration(password: 'secret123');

        expect(controller.state.firstNames, '  Jean  Marc  ');
        expect(payload?['firstNames'], 'Jean  Marc');
        expect(payload?['lastName'], 'Kouassi Yao');
      },
    );

    test('treats names containing only spaces as empty', () {
      final controller = _controller(_DraftRepository());
      addTearDown(controller.dispose);

      controller.updateDraftFields(
        phoneNumber: '0700000000',
        email: '',
        firstNames: '   ',
        lastName: ' ',
        genre: null,
      );

      expect(controller.state.firstNames, isNull);
      expect(controller.state.lastName, isNull);
    });
  });
}

AuthRegisterFlowController _controller(
  _DraftRepository repository, {
  AuthRegisterCompleteAction? completeRegistrationAction,
}) {
  return AuthRegisterFlowController(
    role: AuthRegisterRole.passenger,
    userRegistrationType: 'USER',
    draftRepository: repository,
    sendOtpAction: (phoneNumber, {email}) async {},
    verifyOtpAction: (phoneNumber, verificationCode) async {},
    completeRegistrationAction:
        completeRegistrationAction ?? (payload) async {},
    isAuthenticated: () => false,
  );
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
