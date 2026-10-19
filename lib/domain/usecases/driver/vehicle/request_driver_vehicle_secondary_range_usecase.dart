library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../models/driver_kyc_document_file.dart';
import '../../../models/driver_vehicle_document_type.dart';
import '../../../repositories/driver_vehicle_repository.dart';
import '../../../usecases/usecase.dart';
import '../auth/driver_auth_failure_mapper.dart';

class RequestDriverVehicleSecondaryRangeParams {
  const RequestDriverVehicleSecondaryRangeParams({
    required this.vehicleId,
    required this.secondaryRange,
    required this.photos,
  });

  final int vehicleId;
  final String secondaryRange;
  final Map<DriverVehicleDocumentType, DriverKycDocumentFile> photos;
}

class RequestDriverVehicleSecondaryRangeUseCase
    extends UseCase<Map<String, dynamic>, RequestDriverVehicleSecondaryRangeParams> {
  RequestDriverVehicleSecondaryRangeUseCase(this._repository);

  final DriverVehicleRepository _repository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    RequestDriverVehicleSecondaryRangeParams params,
  ) async {
    try {
      final response = await _repository.requestSecondaryRange(
        vehicleId: params.vehicleId,
        secondaryRange: params.secondaryRange,
        photos: params.photos,
      );
      return right(response);
    } catch (error) {
      return left(mapDriverAuthException(error));
    }
  }
}
