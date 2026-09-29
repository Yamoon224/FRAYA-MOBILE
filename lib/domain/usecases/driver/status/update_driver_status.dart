library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_status_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_status_failure_mapper.dart';

class UpdateDriverStatusParams {
  const UpdateDriverStatusParams({required this.isOnline});

  final bool isOnline;
}

class UpdateDriverStatusUseCase
    extends UseCase<void, UpdateDriverStatusParams> {
  UpdateDriverStatusUseCase(this._repository);

  final DriverStatusRepository _repository;

  @override
  Future<Either<Failure, void>> call(UpdateDriverStatusParams params) async {
    try {
      await _repository.updateStatus(isOnline: params.isOnline);
      return const Right(null);
    } catch (error) {
      return left(mapDriverStatusException(error));
    }
  }
}
