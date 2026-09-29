library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/passenger_profile_repository.dart';
import '../auth_failure_mapper.dart';
import '../../usecase.dart';

class UpdatePassengerProfileParams {
  const UpdatePassengerProfileParams({
    required this.userId,
    required this.data,
  });

  final int userId;
  final Map<String, dynamic> data;
}

class UpdatePassengerProfileUseCase
    extends UseCase<Map<String, dynamic>, UpdatePassengerProfileParams> {
  UpdatePassengerProfileUseCase(this._repository);

  final PassengerProfileRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    UpdatePassengerProfileParams params,
  ) async {
    try {
      final response = await _repository.updateProfile(
        userId: params.userId,
        data: params.data,
      );
      return right(response);
    } catch (error) {
      return left(mapAuthException(error));
    }
  }
}
