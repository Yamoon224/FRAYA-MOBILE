library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_ride_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_ride_failure_mapper.dart';

class StartDriverRideParams {
  const StartDriverRideParams({required this.rideId});

  final String rideId;
}

class StartDriverRideUseCase extends UseCase<void, StartDriverRideParams> {
  StartDriverRideUseCase(this._repository);

  final DriverRideRepository _repository;

  @override
  Future<Either<Failure, void>> call(StartDriverRideParams params) async {
    try {
      await _repository.startRide(params.rideId);
      return const Right(null);
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
