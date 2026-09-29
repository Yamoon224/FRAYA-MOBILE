library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../models/driver_ride.dart';
import '../../../repositories/driver_ride_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_ride_failure_mapper.dart';

class GetDriverHistoryRidesUseCase extends UseCaseNoParams<List<DriverRide>> {
  GetDriverHistoryRidesUseCase(this._repository);

  final DriverRideRepository _repository;

  @override
  Future<Either<Failure, List<DriverRide>>> call() async {
    try {
      final rides = await _repository.getHistoryRides();
      return right(rides);
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
