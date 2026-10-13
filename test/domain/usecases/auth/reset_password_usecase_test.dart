import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/error/failures.dart';
import 'package:fraya_mobile/domain/usecases/auth/reset_password_usecase.dart';

import '../../../support/forgot_password_test_doubles.dart';

void main() {
  group('ResetPasswordUsecase', () {
    test('forwards code, password and identifier to the repository', () async {
      final repository = RecordingForgotPasswordRepository();
      final usecase = ResetPasswordUsecase(repository);

      final result = await usecase(
        const ResetPasswordParams(
          verificationCode: '123456',
          newPassword: 'Secret123',
          identifier: '0700000000',
        ),
      );

      expect(result.isRight(), isTrue);
      expect(repository.resetCalls, hasLength(1));
      final call = repository.resetCalls.single;
      expect(call.verificationCode, '123456');
      expect(call.newPassword, 'Secret123');
      expect(call.identifier, '0700000000');
    });

    test('forwards an email identifier unchanged', () async {
      final repository = RecordingForgotPasswordRepository();

      await ResetPasswordUsecase(repository)(
        const ResetPasswordParams(
          verificationCode: '123456',
          newPassword: 'Secret123',
          identifier: 'awa@fraya.ci',
        ),
      );

      expect(repository.resetCalls.single.identifier, 'awa@fraya.ci');
    });

    test('maps repository errors to failures', () async {
      final repository = RecordingForgotPasswordRepository(
        resetError: const ServerException(
          message: 'Code invalide ou expiré',
          statusCode: 400,
        ),
      );

      final result = await ResetPasswordUsecase(repository)(
        const ResetPasswordParams(
          verificationCode: '000000',
          newPassword: 'Secret123',
          identifier: '0700000000',
        ),
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ServerFailure>());
      expect(failure!.message, 'Code invalide ou expiré');
    });
  });
}
