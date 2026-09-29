library;

import '../../core/models/ride_category.dart';
import '../models/active_ride.dart';
import '../models/ride_share_link.dart';

class RideEstimateStop {
  const RideEstimateStop({required this.position, required this.placeId});

  final int position;
  final String placeId;
}

class RidePriceEstimate {
  const RidePriceEstimate({
    required this.range,
    required this.totalPrice,
    required this.amountReceived,
  });

  final String range;
  final int totalPrice;
  final int amountReceived;
}

class CalculateRidePriceParams {
  const CalculateRidePriceParams({
    required this.latDeparture,
    required this.longDeparture,
    this.arrivalPlaceId,
    required this.arrivalLat,
    required this.arrivalLong,
    required this.range,
    this.stops = const [],
    this.promoCode = '',
    this.waitingSeconds = 0,
  });

  final double latDeparture;
  final double longDeparture;
  final String? arrivalPlaceId;
  final double arrivalLat;
  final double arrivalLong;
  final String range;
  final List<RideEstimateStop> stops;
  final String promoCode;
  final int waitingSeconds;
}

class CalculateRidePricesParams {
  const CalculateRidePricesParams({
    required this.latDeparture,
    required this.longDeparture,
    this.arrivalPlaceId,
    required this.arrivalLat,
    required this.arrivalLong,
    this.stops = const [],
    this.promoCode = '',
    this.waitingSeconds = 0,
  });

  final double latDeparture;
  final double longDeparture;
  final String? arrivalPlaceId;
  final double arrivalLat;
  final double arrivalLong;
  final List<RideEstimateStop> stops;
  final String promoCode;
  final int waitingSeconds;
}

class RequestRideParams {
  const RequestRideParams({
    required this.userId,
    required this.requestedRange,
    required this.departureAddress,
    required this.latDeparture,
    required this.longDeparture,
    required this.arrivalAddress,
    required this.arrivalLat,
    required this.arrivalLong,
    this.arrivalPlaceId,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.estimatedPrice,
    required this.amountReceived,
    required this.finalPrice,
    required this.durationInTraffic,
    required this.trafficPercentage,
    required this.paymentMethod,
    this.stops = const [],
    this.passengerComment = '',
    this.finalDistanceKm = 0,
    this.finalDuration = 0,
  });

  final int userId;
  final String requestedRange;
  final String departureAddress;
  final double latDeparture;
  final double longDeparture;
  final String arrivalAddress;
  final double arrivalLat;
  final double arrivalLong;
  final String? arrivalPlaceId;
  final double estimatedDistance;
  final int estimatedDuration;
  final int estimatedPrice;
  final int amountReceived;
  final int finalPrice;
  final String durationInTraffic;
  final String trafficPercentage;
  final String paymentMethod;
  final List<RideEstimateStop> stops;
  final String passengerComment;
  final double finalDistanceKm;
  final int finalDuration;
}

enum RateRideOutcome { submitted, alreadySubmitted }

abstract class BookingRepository {
  Future<List<RideCategory>> getRideCategories();

  Future<Map<String, RidePriceEstimate>> calculateRidePrices(
    CalculateRidePricesParams params,
  );

  Future<int?> calculateRidePrice(CalculateRidePriceParams params);

  Future<String> requestRide(RequestRideParams params);

  Future<bool> cancelRide(String rideId, {String? reason});

  /// Charge les courses visibles pour l'utilisateur authentifie.
  ///
  /// Le backend filtre actuellement via le Bearer token.
  /// Le [userId] est conserve pour compatibilite avec le contrat existant.
  Future<List<Map<String, dynamic>>> getUserRides(int userId);

  Future<ActiveRide?> getActiveRide(int userId, {String? rideId});
  Future<RideShareLink> createRideShareLink({
    required String rideId,
    int expiresIn = 60,
  });
  Future<RateRideOutcome> rateRide({
    required String rideId,
    required int rating,
    String? comment,
    double? tip,
  });
  Future<bool> triggerSos({
    required String rideId,
    required int userId,
    required double lat,
    required double lng,
    String? notes,
  });
  Future<bool> createSupportTicket({
    required String rideId,
    required int userId,
    required String category,
    String? description,
  });
}
