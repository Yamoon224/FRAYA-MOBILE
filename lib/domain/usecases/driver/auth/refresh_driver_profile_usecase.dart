library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_auth_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_auth_failure_mapper.dart';

class RefreshDriverProfileUseCase extends UseCaseNoParams<Map<String, dynamic>> {
  RefreshDriverProfileUseCase(this._repository);

  final DriverAuthRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call() async {
    try {
      final response = await _repository.fetchProfile();
      return right(response);
    } catch (error) {
      return left(mapDriverAuthException(error));
    }
  }
}
