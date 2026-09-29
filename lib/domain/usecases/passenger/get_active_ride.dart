library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../models/active_ride.dart';
import '../../repositories/booking_repository.dart';
import '../usecase.dart';
import 'booking_failure_mapper.dart';

class GetActiveRideParams {
  const GetActiveRideParams({
    required this.userId,
    this.rideId,
  });

  final int userId;
  final String? rideId;
}

class GetActiveRideUseCase extends UseCase<ActiveRide?, GetActiveRideParams> {
  GetActiveRideUseCase(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, ActiveRide?>> call(
    GetActiveRideParams params,
  ) async {
    try {
      final ride = await _repository.getActiveRide(
        params.userId,
        rideId: params.rideId,
      );
      return right(ride);
    } catch (error) {
      return left(mapBookingException(error));
    }
  }
}
