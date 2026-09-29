library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/passenger_profile_repository.dart';
import '../auth_failure_mapper.dart';
import '../../usecase.dart';

class UpdatePassengerProfilePhotoParams {
  const UpdatePassengerProfilePhotoParams({
    required this.userId,
    required this.filePath,
    required this.fileName,
  });

  final int userId;
  final String filePath;
  final String fileName;
}

class UpdatePassengerProfilePhotoUseCase
    extends UseCase<Map<String, dynamic>, UpdatePassengerProfilePhotoParams> {
  UpdatePassengerProfilePhotoUseCase(this._repository);

  final PassengerProfileRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    UpdatePassengerProfilePhotoParams params,
  ) async {
    try {
      final response = await _repository.updateProfilePhoto(
        userId: params.userId,
        filePath: params.filePath,
        fileName: params.fileName,
      );
      return right(response);
    } catch (error) {
      return left(mapAuthException(error));
    }
  }
}
