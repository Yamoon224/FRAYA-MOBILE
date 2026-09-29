library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_status_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_status_failure_mapper.dart';

class SendDriverHeartbeatUseCase extends UseCase<void, NoParams> {
  SendDriverHeartbeatUseCase(this._repository);

  final DriverStatusRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await _repository.sendHeartbeat();
      return const Right(null);
    } catch (error) {
      return left(mapDriverStatusException(error));
    }
  }
}
