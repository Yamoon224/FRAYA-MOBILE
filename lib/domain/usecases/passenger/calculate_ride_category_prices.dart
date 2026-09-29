library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/models/ride_category.dart';
import '../../../core/utils/logger.dart';
import '../../repositories/booking_repository.dart';
import '../usecase.dart';
import 'booking_failure_mapper.dart';

class CalculateRideCategoryPricesParams {
  const CalculateRideCategoryPricesParams({
    required this.baseCategories,
    required this.latDeparture,
    required this.longDeparture,
    this.arrivalPlaceId,
    required this.arrivalLat,
    required this.arrivalLong,
    this.stops = const [],
    this.promoCode = '',
    this.waitingSeconds = 0,
  });

  final List<RideCategory> baseCategories;
  final double latDeparture;
  final double longDeparture;
  final String? arrivalPlaceId;
  final double arrivalLat;
  final double arrivalLong;
  final List<RideEstimateStop> stops;
  final String promoCode;
  final int waitingSeconds;
}

class CalculateRideCategoryPricesUseCase
    extends UseCase<List<RideCategory>, CalculateRideCategoryPricesParams> {
  CalculateRideCategoryPricesUseCase(this._repository);

  final BookingRepository _repository;

  @override
  Future<Either<Failure, List<RideCategory>>> call(
    CalculateRideCategoryPricesParams params,
  ) async {
    try {
      final estimatesByRange = await _resolvePrices(params);
      if (estimatesByRange.isEmpty) {
        return left(
          const ServerFailure(message: 'Unable to calculate ride prices.'),
        );
      }
      final hasMissingPrice = params.baseCategories.any(
        (category) => !estimatesByRange.containsKey(category.id),
      );
      if (hasMissingPrice) {
        return left(
          const ServerFailure(message: 'Incomplete ride prices response.'),
        );
      }
      final pricedCategories = [
        for (final category in params.baseCategories)
          category.copyWith(
            price: estimatesByRange[category.id]!.totalPrice,
            amountReceived: estimatesByRange[category.id]!.amountReceived,
          ),
      ]..sort((left, right) => left.price.compareTo(right.price));
      return right(pricedCategories);
    } catch (error, stack) {
      logger.error('calculateRidePrices EXCEPTION', error, stack);
      return left(mapBookingException(error));
    }
  }

  Future<Map<String, RidePriceEstimate>> _resolvePrices(
    CalculateRideCategoryPricesParams params,
  ) async {
    return _repository.calculateRidePrices(
      CalculateRidePricesParams(
        latDeparture: params.latDeparture,
        longDeparture: params.longDeparture,
        arrivalPlaceId: params.arrivalPlaceId,
        arrivalLat: params.arrivalLat,
        arrivalLong: params.arrivalLong,
        stops: params.stops,
        promoCode: params.promoCode,
        waitingSeconds: params.waitingSeconds,
      ),
    );
  }
}
