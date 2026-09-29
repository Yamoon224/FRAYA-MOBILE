library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_ride_repository.dart';
import '../../../usecases/usecase.dart';
import 'driver_ride_failure_mapper.dart';

class CancelDriverRideParams {
  const CancelDriverRideParams({
    required this.rideId,
    this.reason,
  });

  final String rideId;
  final String? reason;
}

class CancelDriverRideUseCase extends UseCase<void, CancelDriverRideParams> {
  CancelDriverRideUseCase(this._repository);

  final DriverRideRepository _repository;

  @override
  Future<Either<Failure, void>> call(CancelDriverRideParams params) async {
    try {
      await _repository.cancelRide(params.rideId, reason: params.reason);
      return const Right(null);
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
