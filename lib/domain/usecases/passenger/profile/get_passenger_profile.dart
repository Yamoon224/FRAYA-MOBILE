library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/passenger_profile_repository.dart';
import '../auth_failure_mapper.dart';
import '../../usecase.dart';

class GetPassengerProfileUseCase extends UseCaseNoParams<Map<String, dynamic>> {
  GetPassengerProfileUseCase(this._repository);

  final PassengerProfileRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call() async {
    try {
      final profile = await _repository.getProfile();
      return right(profile);
    } catch (error) {
      return left(mapAuthException(error));
    }
  }
}
