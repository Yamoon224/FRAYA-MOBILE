library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_auth_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_auth_failure_mapper.dart';

class LoginDriverParams {
  const LoginDriverParams({required this.phoneNumber, required this.password});

  final String phoneNumber;
  final String password;
}

class LoginDriverUseCase extends UseCase<Map<String, dynamic>, LoginDriverParams> {
  LoginDriverUseCase(this._repository);

  final DriverAuthRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    LoginDriverParams params,
  ) async {
    try {
      final response = await _repository.login(
        params.phoneNumber,
        params.password,
      );
      return right(response);
    } catch (error) {
      return left(mapDriverAuthException(error));
    }
  }
}
