import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';

void main() {
  test('Ride.fromMap parses placeIds from top-level fields', () {
    final ride = Ride.fromMap({
      'id': '1',
      'departureAddress': 'Cocody',
      'arrivalAddress': 'Aeroport',
      'departurePlaceId': 'dep_place_1',
      'arrivalPlaceId': 'arr_place_1',
      'finalPrice': 2500,
      'createdAt': '2026-05-20T10:00:00.000Z',
      'status': 'COMPLETED',
      'requestedRange': 'MAGIC',
    });

    expect(ride.departurePlaceId, 'dep_place_1');
    expect(ride.arrivalPlaceId, 'arr_place_1');
  });

  test('Ride.fromMap parses destination/start nested placeIds', () {
    final ride = Ride.fromMap({
      'id': '2',
      'departureAddress': 'Cocody',
      'arrivalAddress': 'Aeroport',
      'start': {'placeId': 'dep_nested'},
      'destination': {'placeId': 'arr_nested'},
      'finalPrice': 2600,
      'createdAt': '2026-05-20T10:00:00.000Z',
      'status': 'COMPLETED',
      'requestedRange': 'MAGIC',
    });

    expect(ride.departurePlaceId, 'dep_nested');
    expect(ride.arrivalPlaceId, 'arr_nested');
  });

  test('Ride.fromMap keeps placeIds nullable for backward compatibility', () {
    final ride = Ride.fromMap({
      'id': '3',
      'departureAddress': 'Cocody',
      'arrivalAddress': 'Aeroport',
      'finalPrice': 2700,
      'createdAt': '2026-05-20T10:00:00.000Z',
      'status': 'COMPLETED',
      'requestedRange': 'MAGIC',
    });

    expect(ride.departurePlaceId, isNull);
    expect(ride.arrivalPlaceId, isNull);
  });
}
