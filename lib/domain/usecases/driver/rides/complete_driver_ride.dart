library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_ride_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_ride_failure_mapper.dart';

class CompleteDriverRideParams {
  const CompleteDriverRideParams({
    required this.rideId,
    required this.finalDistanceKm,
    required this.finalDurationMin,
    required this.finalPrice,
    required this.additionnalFreeSeconds,
  });

  final String rideId;
  final double finalDistanceKm;
  final int finalDurationMin;
  final int finalPrice;
  final int additionnalFreeSeconds;
}

class CompleteDriverRideUseCase
    extends UseCase<void, CompleteDriverRideParams> {
  CompleteDriverRideUseCase(this._repository);

  final DriverRideRepository _repository;

  @override
  Future<Either<Failure, void>> call(CompleteDriverRideParams params) async {
    try {
      await _repository.completeRide(
        params.rideId,
        finalDistanceKm: params.finalDistanceKm,
        finalDurationMin: params.finalDurationMin,
        finalPrice: params.finalPrice,
        additionnalFreeSeconds: params.additionnalFreeSeconds,
      );
      return const Right(null);
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
