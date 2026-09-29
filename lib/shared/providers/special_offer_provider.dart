library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/special_offer.dart';
import '../../domain/usecases/shared/share_special_offer.dart';
import 'special_offer_dependencies.dart';

class SpecialOfferShareController {
  const SpecialOfferShareController(this._shareSpecialOfferUseCase);

  final ShareSpecialOfferUseCase _shareSpecialOfferUseCase;

  Future<String?> shareOffer(SpecialOffer offer) async {
    final result = await _shareSpecialOfferUseCase(offer);
    return result.fold((failure) => failure.message, (_) => null);
  }
}

final activeSpecialOfferProvider =
    FutureProvider.family<SpecialOffer?, SpecialOfferAudience>((
      ref,
      audience,
    ) async {
      final useCase = ref.watch(getActiveSpecialOfferUseCaseProvider);
      final result = await useCase(audience);
      return result.fold((_) => null, (offer) => offer);
    });

final activeSpecialOfferCountProvider =
    FutureProvider.family<int, SpecialOfferAudience>((ref, audience) async {
      final repository = ref.watch(specialOfferRepositoryProvider);
      return repository.getActiveOfferCount(audience);
    });

final specialOfferShareControllerProvider =
    Provider<SpecialOfferShareController>((ref) {
      final useCase = ref.watch(shareSpecialOfferUseCaseProvider);
      return SpecialOfferShareController(useCase);
    });
