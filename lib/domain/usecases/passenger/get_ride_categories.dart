library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/models/ride_category.dart';
import '../../repositories/booking_repository.dart';
import '../usecase.dart';

class GetRideCategoriesUseCase extends UseCase<List<RideCategory>, NoParams> {
  GetRideCategoriesUseCase(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, List<RideCategory>>> call(NoParams params) async {
    try {
      final categories = await _repository.getRideCategories();
      if (categories.isEmpty) {
        return left(const ServerFailure(message: 'Aucune catégorie disponible'));
      }
      return right(categories);
    } catch (e) {
      return left(ServerFailure(message: 'Erreur chargement catégories: $e'));
    }
  }
}
