import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/remote/booking_request_payload_builder.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';

void main() {
  test('builds the current ride request payload without commission fields', () {
    final payload = BookingRequestPayloadBuilder.build(
      const RequestRideParams(
        userId: 1,
        requestedRange: 'MAGIC',
        departureAddress: 'Cocody',
        latDeparture: 5.39,
        longDeparture: -3.97,
        arrivalAddress: 'Aeroport',
        arrivalLat: 5.26,
        arrivalLong: -3.94,
        arrivalPlaceId: 'destination_place_id',
        stops: [RideEstimateStop(position: 1, placeId: 'stop_place_id')],
        estimatedDistance: 19.1,
        estimatedDuration: 75,
        estimatedPrice: 5700,
        amountReceived: 5200,
        finalPrice: 5700,
        durationInTraffic: '44',
        trafficPercentage: '30',
        paymentMethod: 'CASH',
      ),
    );

    expect(payload, {
      'userId': 1,
      'requestedRange': 'MAGIC',
      'departureAddress': 'Cocody',
      'latDeparture': 5.39,
      'longDeparture': -3.97,
      'arrivalAddress': 'Aeroport',
      'arrivalLat': 5.26,
      'arrivalLong': -3.94,
      'stops': [
        {'position': 1, 'placeId': 'stop_place_id'},
      ],
      'estimatedDistance': 19.1,
      'estimatedDuration': 75,
      'estimatedPrice': 5700,
      'paymentMethod': 'CASH',
      'passengerComment': '',
      'finalDistanceKm': 0.0,
      'finalDuration': 0,
      'finalPrice': 5700,
      'amountReceived': 5200,
      'durationInTraffic': '44',
      'trafficPercentage': '30',
    });
    expect(payload.containsKey('amountCommission'), isFalse);
    expect(payload.containsKey('commissionPrice'), isFalse);
    expect(payload.containsKey('arrivalPlaceId'), isFalse);
    expect(payload.containsKey('promoCode'), isFalse);
    expect(payload.containsKey('waitingSeconds'), isFalse);
    expect(payload.containsKey('range'), isFalse);
  });
}
