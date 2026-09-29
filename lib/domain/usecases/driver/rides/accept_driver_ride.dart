library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_ride_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_ride_failure_mapper.dart';

class AcceptDriverRideParams {
  const AcceptDriverRideParams({
    required this.rideId,
    required this.driverId,
    required this.vehicleId,
  });

  final String rideId;
  final int driverId;
  final int vehicleId;
}

class AcceptDriverRideUseCase extends UseCase<void, AcceptDriverRideParams> {
  AcceptDriverRideUseCase(this._repository);

  final DriverRideRepository _repository;

  @override
  Future<Either<Failure, void>> call(AcceptDriverRideParams params) async {
    try {
      await _repository.acceptRide(
        params.rideId,
        driverId: params.driverId,
        vehicleId: params.vehicleId,
      );
      return const Right(null);
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
