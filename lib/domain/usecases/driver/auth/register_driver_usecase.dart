library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_auth_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_auth_failure_mapper.dart';

class RegisterDriverParams {
  const RegisterDriverParams({required this.userData});

  final Map<String, dynamic> userData;
}

class RegisterDriverUseCase
    extends UseCase<Map<String, dynamic>, RegisterDriverParams> {
  RegisterDriverUseCase(this._repository);

  final DriverAuthRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    RegisterDriverParams params,
  ) async {
    try {
      final response = await _repository.register(params.userData);
      return right(response);
    } catch (error) {
      return left(mapDriverAuthException(error));
    }
  }
}
