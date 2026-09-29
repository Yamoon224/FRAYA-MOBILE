import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../repositories/booking_repository.dart';
import '../usecase.dart';
import 'booking_failure_mapper.dart';

class RateRideParams {
  const RateRideParams({
    required this.rideId,
    required this.rating,
    this.comment,
    this.tip,
  });

  final String rideId;
  final int rating;
  final String? comment;
  final double? tip;
}

class RateRideUseCase extends UseCase<RateRideOutcome, RateRideParams> {
  RateRideUseCase(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, RateRideOutcome>> call(RateRideParams params) async {
    try {
      final success = await _repository.rateRide(
        rideId: params.rideId,
        rating: params.rating,
        comment: params.comment,
        tip: params.tip,
      );
      return Right(success);
    } catch (e) {
      return Left(mapBookingException(e));
    }
  }
}
