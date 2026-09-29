library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../features/passenger/auth/repositories/passenger_auth_repository.dart';
import '../auth_failure_mapper.dart';
import '../../usecase.dart';

class RegisterStep2Params {
  const RegisterStep2Params({
    required this.phoneNumber,
    required this.verificationCode,
  });

  final String phoneNumber;
  final String verificationCode;
}

class RegisterStep2Usecase extends UseCase<void, RegisterStep2Params> {
  RegisterStep2Usecase(this._repository);

  final PassengerAuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(RegisterStep2Params params) async {
    try {
      await _repository.registerStep2(params.phoneNumber, params.verificationCode);
      return right(null);
    } catch (error) {
      return left(mapAuthException(error));
    }
  }
}
