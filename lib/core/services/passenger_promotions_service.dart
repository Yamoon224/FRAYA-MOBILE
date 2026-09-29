library;

import '../../data/sources/remote/passenger_promotions_remote_data_source.dart';
import '../../features/passenger/promotions/models/promo_apply_result.dart';

class PassengerPromotionsService {
  PassengerPromotionsService({
    PassengerPromotionsRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource =
           remoteDataSource ?? PassengerPromotionsRemoteDataSource();

  final PassengerPromotionsRemoteDataSource _remoteDataSource;

  Future<PromoApplyResult> applyCode({
    required String code,
    required int userId,
    required double initialPrice,
    int? courseId,
  }) async {
    final result = await _remoteDataSource.applyPromoCode(
      code: code,
      userId: userId,
      initialPrice: initialPrice,
      courseId: courseId,
    );
    return PromoApplyResult.fromMap(result);
  }
}
