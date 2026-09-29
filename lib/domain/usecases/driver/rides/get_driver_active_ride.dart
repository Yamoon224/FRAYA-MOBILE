library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../models/driver_ride.dart';
import '../../../repositories/driver_ride_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_ride_failure_mapper.dart';

class GetDriverActiveRideParams {
  const GetDriverActiveRideParams({
    required this.driverId,
    this.rideId,
  });

  final int driverId;
  final String? rideId;
}

class GetDriverActiveRideUseCase
    extends UseCase<DriverRide?, GetDriverActiveRideParams> {
  GetDriverActiveRideUseCase(this._repository);

  final DriverRideRepository _repository;

  @override
  Future<Either<Failure, DriverRide?>> call(
    GetDriverActiveRideParams params,
  ) async {
    try {
      final ride = await _repository.getActiveRide(
        params.driverId,
        rideId: params.rideId,
      );
      return right(ride);
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
