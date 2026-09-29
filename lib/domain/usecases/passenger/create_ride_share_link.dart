import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../models/ride_share_link.dart';
import '../../repositories/booking_repository.dart';
import '../usecase.dart';
import 'booking_failure_mapper.dart';

class CreateRideShareLinkParams {
  const CreateRideShareLinkParams({
    required this.rideId,
    this.expiresIn = 60,
  });

  final String rideId;
  final int expiresIn;
}

class CreateRideShareLinkUseCase
    extends UseCase<RideShareLink, CreateRideShareLinkParams> {
  CreateRideShareLinkUseCase(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, RideShareLink>> call(
    CreateRideShareLinkParams params,
  ) async {
    try {
      final link = await _repository.createRideShareLink(
        rideId: params.rideId,
        expiresIn: params.expiresIn,
      );
      return Right(link);
    } catch (error) {
      return Left(mapBookingException(error));
    }
  }
}
