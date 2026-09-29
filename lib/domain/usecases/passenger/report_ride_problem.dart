import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../repositories/booking_repository.dart';
import '../usecase.dart';
import 'booking_failure_mapper.dart';

class ReportRideProblemParams {
  const ReportRideProblemParams({
    required this.rideId,
    required this.userId,
    required this.category,
    this.description,
  });

  final String rideId;
  final int userId;
  final String category;
  final String? description;
}

class ReportRideProblemUseCase
    extends UseCase<bool, ReportRideProblemParams> {
  ReportRideProblemUseCase(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, bool>> call(ReportRideProblemParams params) async {
    try {
      final success = await _repository.createSupportTicket(
        rideId: params.rideId,
        userId: params.userId,
        category: params.category,
        description: params.description,
      );
      return Right(success);
    } catch (error) {
      return Left(mapBookingException(error));
    }
  }
}
