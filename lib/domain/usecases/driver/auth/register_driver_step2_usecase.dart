library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_auth_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_auth_failure_mapper.dart';

class RegisterDriverStep2Params {
  const RegisterDriverStep2Params({
    required this.phoneNumber,
    required this.verificationCode,
  });

  final String phoneNumber;
  final String verificationCode;
}

class RegisterDriverStep2UseCase
    extends UseCase<void, RegisterDriverStep2Params> {
  RegisterDriverStep2UseCase(this._repository);

  final DriverAuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(RegisterDriverStep2Params params) async {
    try {
      await _repository.registerStep2(
        params.phoneNumber,
        params.verificationCode,
      );
      return right(null);
    } catch (error) {
      return left(mapDriverAuthException(error));
    }
  }
}
