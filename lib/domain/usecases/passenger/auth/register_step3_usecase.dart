library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../features/passenger/auth/repositories/passenger_auth_repository.dart';
import '../auth_failure_mapper.dart';
import '../../usecase.dart';

class RegisterStep3Params {
  const RegisterStep3Params({required this.userData});

  final Map<String, dynamic> userData;
}

class RegisterStep3Usecase extends UseCase<Map<String, dynamic>, RegisterStep3Params> {
  RegisterStep3Usecase(this._repository);

  final PassengerAuthRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    RegisterStep3Params params,
  ) async {
    try {
      final response = await _repository.registerStep3(params.userData);
      return right(response);
    } catch (error) {
      return left(mapAuthException(error));
    }
  }
}
