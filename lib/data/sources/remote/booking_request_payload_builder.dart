import '../../../domain/repositories/booking_repository.dart';

class BookingRequestPayloadBuilder {
  const BookingRequestPayloadBuilder._();

  static Map<String, dynamic> build(RequestRideParams params) {
    return <String, dynamic>{
      'userId': params.userId,
      'requestedRange': params.requestedRange,
      'departureAddress': params.departureAddress,
      'latDeparture': params.latDeparture,
      'longDeparture': params.longDeparture,
      'arrivalAddress': params.arrivalAddress,
      'arrivalLat': params.arrivalLat,
      'arrivalLong': params.arrivalLong,
      'stops': [
        for (final stop in params.stops)
          {'position': stop.position, 'placeId': stop.placeId},
      ],
      'estimatedDistance': params.estimatedDistance,
      'estimatedDuration': params.estimatedDuration,
      'estimatedPrice': params.estimatedPrice,
      'paymentMethod': params.paymentMethod,
      'passengerComment': params.passengerComment,
      'finalDistanceKm': params.finalDistanceKm,
      'finalDuration': params.finalDuration,
      'finalPrice': params.finalPrice,
      'amountReceived': params.amountReceived,
      'durationInTraffic': params.durationInTraffic,
      'trafficPercentage': params.trafficPercentage,
    };
  }
}
