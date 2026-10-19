library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

import '../../../repositories/driver_vehicle_repository.dart';
import '../../../usecases/usecase.dart';
import '../auth/driver_auth_failure_mapper.dart';

class UpdateDriverVehicleSecondaryRangeParams {
  const UpdateDriverVehicleSecondaryRangeParams({required this.vehicleId, required this.secondaryRange});

  final int vehicleId;

  /// `null` retire la seconde gamme.
  final String? secondaryRange;
}

class UpdateDriverVehicleSecondaryRangeUseCase
    extends UseCase<Map<String, dynamic>, UpdateDriverVehicleSecondaryRangeParams> {
  UpdateDriverVehicleSecondaryRangeUseCase(this._repository);

  final DriverVehicleRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    UpdateDriverVehicleSecondaryRangeParams params,
  ) async {
    try {
      final response = await _repository.updateSecondaryRange(
        vehicleId: params.vehicleId,
        secondaryRange: params.secondaryRange,
      );
      return right(response);
    } catch (error) {
      return left(mapDriverAuthException(error));
    }
  }
}
