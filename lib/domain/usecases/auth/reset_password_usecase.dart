library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../data/repositories/forgot_password_repository.dart';
import '../passenger/auth_failure_mapper.dart';
import '../usecase.dart';

class ResetPasswordParams {
  const ResetPasswordParams({
    required this.verificationCode,
    required this.newPassword,
  });

  final String verificationCode;
  final String newPassword;
}

class ResetPasswordUsecase extends UseCase<void, ResetPasswordParams> {
  ResetPasswordUsecase(this._repository);

  final ForgotPasswordRepository _repository;

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    try {
      await _repository.resetPassword(
        params.verificationCode,
        params.newPassword,
      );
      return right(null);
    } catch (error) {
      return left(mapAuthException(error));
    }
  }
}
