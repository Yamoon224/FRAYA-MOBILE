library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_auth_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_auth_failure_mapper.dart';

class RegisterDriverStep1Params {
  const RegisterDriverStep1Params({required this.phoneNumber, this.email});

  final String phoneNumber;
  final String? email;
}

class RegisterDriverStep1UseCase
    extends UseCase<void, RegisterDriverStep1Params> {
  RegisterDriverStep1UseCase(this._repository);

  final DriverAuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(RegisterDriverStep1Params params) async {
    try {
      await _repository.registerStep1(params.phoneNumber, email: params.email);
      return right(null);
    } catch (error) {
      return left(mapDriverAuthException(error));
    }
  }
}
