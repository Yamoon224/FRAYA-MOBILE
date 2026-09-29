library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_ride_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_ride_failure_mapper.dart';

class MarkDriverRideArrivedParams {
  const MarkDriverRideArrivedParams({
    required this.rideId,
    required this.driverLat,
    required this.driverLng,
  });

  final String rideId;
  final double driverLat;
  final double driverLng;
}

class MarkDriverRideArrivedUseCase
    extends UseCase<void, MarkDriverRideArrivedParams> {
  MarkDriverRideArrivedUseCase(this._repository);

  final DriverRideRepository _repository;

  @override
  Future<Either<Failure, void>> call(
    MarkDriverRideArrivedParams params,
  ) async {
    try {
      await _repository.markArrived(
        params.rideId,
        driverLat: params.driverLat,
        driverLng: params.driverLng,
      );
      return const Right(null);
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
