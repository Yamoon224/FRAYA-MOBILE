library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../features/passenger/auth/repositories/passenger_auth_repository.dart';
import '../auth_failure_mapper.dart';
import '../../usecase.dart';

class LoginPassengerParams {
  const LoginPassengerParams({required this.phoneNumber, required this.password});

  final String phoneNumber;
  final String password;
}

class LoginPassengerUsecase extends UseCase<Map<String, dynamic>, LoginPassengerParams> {
  LoginPassengerUsecase(this._repository);

  final PassengerAuthRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    LoginPassengerParams params,
  ) async {
    try {
      final response = await _repository.login(params.phoneNumber, params.password);
      return right(response);
    } catch (error) {
      return left(mapAuthException(error));
    }
  }
}
