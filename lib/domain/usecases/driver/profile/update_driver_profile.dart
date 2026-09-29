library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_profile_repository.dart';
import '../../passenger/auth_failure_mapper.dart';
import '../../usecase.dart';

class UpdateDriverProfileParams {
  const UpdateDriverProfileParams({required this.userId, required this.data});

  final int userId;
  final Map<String, dynamic> data;
}

class UpdateDriverProfileUseCase
    extends UseCase<Map<String, dynamic>, UpdateDriverProfileParams> {
  UpdateDriverProfileUseCase(this._repository);

  final DriverProfileRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    UpdateDriverProfileParams params,
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
