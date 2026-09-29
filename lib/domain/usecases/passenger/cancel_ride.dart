library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../repositories/booking_repository.dart';
import '../usecase.dart';
import 'booking_failure_mapper.dart';

class CancelRideParams {
  const CancelRideParams({
    required this.rideId,
    this.reason,
  });

  final String rideId;
  final String? reason;
}

class CancelRideUseCase extends UseCase<bool, CancelRideParams> {
  CancelRideUseCase(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, bool>> call(CancelRideParams params) async {
    try {
      final cancelled = await _repository.cancelRide(
        params.rideId,
        reason: params.reason,
      );
      return right(cancelled);
    } catch (error) {
      return left(mapBookingException(error));
    }
  }
}
