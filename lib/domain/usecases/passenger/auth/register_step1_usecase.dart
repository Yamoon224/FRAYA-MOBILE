library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../features/passenger/auth/repositories/passenger_auth_repository.dart';
import '../auth_failure_mapper.dart';
import '../../usecase.dart';

class RegisterStep1Params {
  const RegisterStep1Params({required this.phoneNumber, this.email});

  final String phoneNumber;
  final String? email;
}

class RegisterStep1Usecase extends UseCase<void, RegisterStep1Params> {
  RegisterStep1Usecase(this._repository);

  final PassengerAuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(RegisterStep1Params params) async {
    try {
      await _repository.registerStep1(params.phoneNumber, email: params.email);
      return right(null);
    } catch (error) {
      return left(mapAuthException(error));
    }
  }
}
