library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../data/repositories/forgot_password_repository.dart';
import '../passenger/auth_failure_mapper.dart';
import '../usecase.dart';

class ForgotPasswordParams {
  const ForgotPasswordParams({required this.identifier});

  /// Numéro de téléphone ou adresse e-mail.
  final String identifier;
}

class ForgotPasswordUsecase extends UseCase<void, ForgotPasswordParams> {
  ForgotPasswordUsecase(this._repository);

  final ForgotPasswordRepository _repository;

  @override
  Future<Either<Failure, void>> call(ForgotPasswordParams params) async {
    try {
      await _repository.sendResetCode(params.identifier);
      return right(null);
    } catch (error) {
      return left(mapAuthException(error));
    }
  }
}
