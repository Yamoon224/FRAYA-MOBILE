library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/services/special_offer_share_service.dart';
import '../../models/special_offer.dart';
import '../usecase.dart';

class ShareSpecialOfferUseCase extends UseCase<void, SpecialOffer> {
  ShareSpecialOfferUseCase(this._shareService);

  final SpecialOfferShareService _shareService;

  @override
  Future<Either<Failure, void>> call(SpecialOffer params) async {
    try {
      await _shareService.shareOffer(params);
      return right(null);
    } catch (error) {
      return left(
        ServerFailure(
          message: 'Impossible de partager l\'offre speciale: $error',
        ),
      );
    }
  }
}
