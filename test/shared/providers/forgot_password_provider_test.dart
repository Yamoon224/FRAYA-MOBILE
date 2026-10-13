import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/usecases/auth/forgot_password_usecase.dart';
import 'package:fraya_mobile/domain/usecases/auth/reset_password_usecase.dart';
import 'package:fraya_mobile/shared/providers/forgot_password_provider.dart';

import '../../support/forgot_password_test_doubles.dart';

ForgotPasswordNotifier _buildNotifier(RecordingForgotPasswordRepository repo) {
  return ForgotPasswordNotifier(
    forgotPasswordUsecase: ForgotPasswordUsecase(repo),
    resetPasswordUsecase: ResetPasswordUsecase(repo),
  );
}

void main() {
  group('ForgotPasswordNotifier', () {
    test('sendResetCode moves to codeSent', () async {
      final repository = RecordingForgotPasswordRepository();
      final notifier = _buildNotifier(repository);

      await notifier.sendResetCode('0700000000');

      expect(repository.sentIdentifiers, ['0700000000']);
      expect(notifier.state.status, ForgotPasswordStatus.codeSent);
    });

    test('resetPassword passes the identifier to the use case', () async {
      final repository = RecordingForgotPasswordRepository();
      final notifier = _buildNotifier(repository);

      await notifier.resetPassword('123456', 'Secret123', 'awa@fraya.ci');

      final call = repository.resetCalls.single;
      expect(call.verificationCode, '123456');
      expect(call.newPassword, 'Secret123');
      expect(call.identifier, 'awa@fraya.ci');
      expect(notifier.state.status, ForgotPasswordStatus.success);
      expect(notifier.state.errorMessage, isNull);
    });

    test('resetPassword exposes the server error message', () async {
      final repository = RecordingForgotPasswordRepository(
        resetError: const ServerException(message: 'Code invalide'),
      );
      final notifier = _buildNotifier(repository);

      await notifier.resetPassword('000000', 'Secret123', '0700000000');

      expect(repository.resetCalls.single.identifier, '0700000000');
      expect(notifier.state.status, ForgotPasswordStatus.error);
      expect(notifier.state.errorMessage, 'Code invalide');
    });
  });
}
