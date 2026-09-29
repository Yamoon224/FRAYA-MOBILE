library;

import '../../domain/models/special_offer.dart';
import '../../domain/repositories/special_offer_repository.dart';
import '../sources/local/special_offer_local_data_source.dart';

class SpecialOfferRepositoryImpl implements SpecialOfferRepository {
  SpecialOfferRepositoryImpl({
    required SpecialOfferLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final SpecialOfferLocalDataSource _localDataSource;

  @override
  Future<SpecialOffer?> getActiveOffer(SpecialOfferAudience audience) async {
    final offers = await _getActiveOffers(audience);
    return offers.isEmpty ? null : offers.first;
  }

  @override
  Future<int> getActiveOfferCount(SpecialOfferAudience audience) async {
    final offers = await _getActiveOffers(audience);
    return offers.length;
  }

  Future<List<SpecialOffer>> _getActiveOffers(
    SpecialOfferAudience audience,
  ) async {
    final offers = await _localDataSource.getOffers();
    return offers
        .where((offer) => offer.isActive && offer.supportsAudience(audience))
        .toList();
  }
}
