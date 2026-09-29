import 'package:dartz/dartz.dart';

import '../../../core/models/directions_models.dart';
import '../../../core/error/failures.dart';
import '../../repositories/directions_repository.dart';
import '../usecase.dart';
import 'booking_failure_mapper.dart';

class GetRouteDirectionsUseCase
    extends UseCase<DirectionsResult?, GetRouteDirectionsParams> {
  GetRouteDirectionsUseCase(this._repository);

  final DirectionsRepository _repository;

  @override
  Future<Either<Failure, DirectionsResult?>> call(
    GetRouteDirectionsParams params,
  ) async {
    try {
      final directions = await _repository.getRouteDirections(params);
      return right(directions);
    } catch (error) {
      return left(mapBookingException(error));
    }
  }
}
