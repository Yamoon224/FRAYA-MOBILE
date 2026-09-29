library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../models/driver_ride.dart';
import '../../../repositories/driver_ride_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_ride_failure_mapper.dart';

class FetchAvailableDriverRidesParams {
  const FetchAvailableDriverRidesParams({
    required this.lat,
    required this.lng,
    required this.radiusKm,
  });

  final double lat;
  final double lng;
  final double radiusKm;
}

class FetchAvailableDriverRidesUseCase
    extends UseCase<List<DriverRide>, FetchAvailableDriverRidesParams> {
  FetchAvailableDriverRidesUseCase(this._repository);

  final DriverRideRepository _repository;

  @override
  Future<Either<Failure, List<DriverRide>>> call(
    FetchAvailableDriverRidesParams params,
  ) async {
    try {
      final rides = await _repository.getAvailableRides(
        lat: params.lat,
        lng: params.lng,
        radiusKm: params.radiusKm,
      );
      return right(rides);
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
