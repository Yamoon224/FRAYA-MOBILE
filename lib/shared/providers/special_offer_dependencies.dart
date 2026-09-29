import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/special_offer_share_service.dart';
import '../../data/repositories/special_offer_repository_impl.dart';
import '../../data/sources/local/special_offer_local_data_source.dart';
import '../../domain/repositories/special_offer_repository.dart';
import '../../domain/usecases/shared/get_active_special_offer.dart';
import '../../domain/usecases/shared/share_special_offer.dart';

final specialOfferLocalDataSourceProvider =
    Provider<SpecialOfferLocalDataSource>((ref) {
      return SpecialOfferLocalDataSource();
    });

final specialOfferRepositoryProvider = Provider<SpecialOfferRepository>((ref) {
  final localDataSource = ref.watch(specialOfferLocalDataSourceProvider);
  return SpecialOfferRepositoryImpl(localDataSource: localDataSource);
});

final getActiveSpecialOfferUseCaseProvider =
    Provider<GetActiveSpecialOfferUseCase>((ref) {
      final repository = ref.watch(specialOfferRepositoryProvider);
      return GetActiveSpecialOfferUseCase(repository);
    });

final specialOfferShareServiceProvider = Provider<SpecialOfferShareService>((
  ref,
) {
  return const SpecialOfferShareService();
});

final shareSpecialOfferUseCaseProvider = Provider<ShareSpecialOfferUseCase>((
  ref,
) {
  final service = ref.watch(specialOfferShareServiceProvider);
  return ShareSpecialOfferUseCase(service);
});
