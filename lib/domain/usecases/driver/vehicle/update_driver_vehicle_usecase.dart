library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../models/driver_vehicle_update.dart';
import '../../../repositories/driver_vehicle_repository.dart';
import '../../../usecases/usecase.dart';
import '../auth/driver_auth_failure_mapper.dart';

class UpdateDriverVehicleParams {
  const UpdateDriverVehicleParams({
    required this.vehicleId,
    required this.update,
  });

  final int vehicleId;
  final DriverVehicleUpdate update;
}

class UpdateDriverVehicleUseCase
    extends UseCase<Map<String, dynamic>, UpdateDriverVehicleParams> {
  UpdateDriverVehicleUseCase(this._repository);

  final DriverVehicleRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    UpdateDriverVehicleParams params,
  ) async {
    try {
      final response = await _repository.updateVehicle(
        vehicleId: params.vehicleId,
        update: params.update,
      );
      return right(response);
    } catch (error) {
      return left(mapDriverAuthException(error));
    }
  }
}
