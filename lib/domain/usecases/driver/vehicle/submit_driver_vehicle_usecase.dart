library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../models/driver_vehicle_submission.dart';
import '../../../repositories/driver_vehicle_repository.dart';
import '../../../usecases/usecase.dart';
import '../auth/driver_auth_failure_mapper.dart';

class SubmitDriverVehicleParams {
  const SubmitDriverVehicleParams({required this.submission});

  final DriverVehicleSubmission submission;
}

class SubmitDriverVehicleUseCase
    extends UseCase<Map<String, dynamic>, SubmitDriverVehicleParams> {
  SubmitDriverVehicleUseCase(this._repository);

  final DriverVehicleRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    SubmitDriverVehicleParams params,
  ) async {
    try {
      final response = await _repository.submitVehicle(
        submission: params.submission,
      );
      return right(response);
    } catch (error) {
      return left(mapDriverAuthException(error));
    }
  }
}
