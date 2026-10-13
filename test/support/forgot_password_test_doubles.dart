import 'package:fraya_mobile/data/repositories/forgot_password_repository.dart';

class ResetPasswordCall {
  const ResetPasswordCall(
    this.verificationCode,
    this.newPassword,
    this.identifier,
  );

  final String verificationCode;
  final String newPassword;
  final String identifier;
}

/// Repository en mémoire : enregistre les appels sans toucher au réseau.
class RecordingForgotPasswordRepository extends ForgotPasswordRepository {
  RecordingForgotPasswordRepository({this.sendError, this.resetError});

  final Object? sendError;
  final Object? resetError;
  final sentIdentifiers = <String>[];
  final resetCalls = <ResetPasswordCall>[];

  @override
  Future<void> sendResetCode(String identifier) async {
    sentIdentifiers.add(identifier);
    if (sendError != null) throw sendError!;
  }

  @override
  Future<void> resetPassword(
    String verificationCode,
    String newPassword,
    String identifier,
  ) async {
    resetCalls.add(ResetPasswordCall(verificationCode, newPassword, identifier));
    if (resetError != null) throw resetError!;
  }
}
