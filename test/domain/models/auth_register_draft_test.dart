import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/auth_register_draft.dart';

void main() {
  group('AuthRegisterDraft', () {
    test('serializes register progress without sensitive fields', () {
      final draft = AuthRegisterDraft(
        role: AuthRegisterRole.driver,
        step: AuthRegisterFlowStep.details,
        phoneNumber: '0700000000',
        email: 'driver@example.com',
        firstNames: 'Jean Marc',
        lastName: 'Kouassi',
        genre: 'MASCULIN',
        updatedAt: DateTime(2026, 7, 2),
      );

      final map = draft.toMap();

      expect(map, isNot(contains('password')));
      expect(map, isNot(contains('confirmPassword')));
      expect(map, isNot(contains('otp')));
      expect(AuthRegisterDraft.fromMap(map).role, AuthRegisterRole.driver);
      expect(AuthRegisterDraft.fromMap(map).step, AuthRegisterFlowStep.details);
    });
  });
}
