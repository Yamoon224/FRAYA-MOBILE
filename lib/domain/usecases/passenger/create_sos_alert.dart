import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../repositories/booking_repository.dart';
import '../usecase.dart';
import 'booking_failure_mapper.dart';

class CreateSosAlertParams {
  const CreateSosAlertParams({
    required this.rideId,
    required this.userId,
    required this.lat,
    required this.lng,
    this.notes,
  });

  final String rideId;
  final int userId;
  final double lat;
  final double lng;
  final String? notes;
}

class CreateSosAlertUseCase extends UseCase<bool, CreateSosAlertParams> {
  CreateSosAlertUseCase(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, bool>> call(CreateSosAlertParams params) async {
    try {
      final success = await _repository.triggerSos(
        rideId: params.rideId,
        userId: params.userId,
        lat: params.lat,
        lng: params.lng,
        notes: params.notes,
      );
      return Right(success);
    } catch (error) {
      return Left(mapBookingException(error));
    }
  }
}
