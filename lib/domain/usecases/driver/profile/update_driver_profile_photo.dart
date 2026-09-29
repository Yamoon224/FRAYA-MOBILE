library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_profile_repository.dart';
import '../../passenger/auth_failure_mapper.dart';
import '../../usecase.dart';

class UpdateDriverProfilePhotoParams {
  const UpdateDriverProfilePhotoParams({
    required this.userId,
    required this.filePath,
    required this.fileName,
  });

  final int userId;
  final String filePath;
  final String fileName;
}

class UpdateDriverProfilePhotoUseCase
    extends UseCase<Map<String, dynamic>, UpdateDriverProfilePhotoParams> {
  UpdateDriverProfilePhotoUseCase(this._repository);

  final DriverProfileRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    UpdateDriverProfilePhotoParams params,
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
