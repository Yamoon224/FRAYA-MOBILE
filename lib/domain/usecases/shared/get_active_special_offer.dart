library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../models/special_offer.dart';
import '../../repositories/special_offer_repository.dart';
import '../usecase.dart';

class GetActiveSpecialOfferUseCase
    extends UseCase<SpecialOffer?, SpecialOfferAudience> {
  GetActiveSpecialOfferUseCase(this._repository);

  final SpecialOfferRepository _repository;

  @override
  Future<Either<Failure, SpecialOffer?>> call(
    SpecialOfferAudience params,
  ) async {
    try {
      final offer = await _repository.getActiveOffer(params);
      return right(offer);
    } catch (error) {
      return left(
        CacheFailure(
          message: 'Impossible de charger l\'offre speciale: $error',
        ),
      );
    }
  }
}
