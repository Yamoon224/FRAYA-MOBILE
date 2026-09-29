library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../repositories/booking_repository.dart';
import '../usecase.dart';
import 'booking_failure_mapper.dart';

class RequestRideUseCase extends UseCase<String, RequestRideParams> {
  RequestRideUseCase(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, String>> call(
    RequestRideParams params,
  ) async {
    try {
      final response = await _repository.requestRide(params);
      return right(response);
    } catch (error) {
      return left(mapBookingException(error));
    }
  }
}
