library;

import '../models/special_offer.dart';

abstract class SpecialOfferRepository {
  Future<SpecialOffer?> getActiveOffer(SpecialOfferAudience audience);

  Future<int> getActiveOfferCount(SpecialOfferAudience audience);
}
