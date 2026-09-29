import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';

void main() {
  group('DriverRide.fromMap', () {
    test('parses backend payload defensively', () {
      final ride = DriverRide.fromMap({
        'id': 14,
        'status': 'ASSIGNED',
        'requestedRange': 'MAGIC',
        'estimatedPrice': 4500,
        'estimatedDistance': 15.2,
        'estimatedDuration': 25,
        'departureAddress': 'Adjame',
        'latDeparture': 5.3484,
        'longDeparture': -4.0135,
        'arrivalAddress': 'Airport',
        'arrivalLat': 5.2612,
        'arrivalLong': -3.9262,
        'createdAt': '2026-05-08T10:00:00.000Z',
        'driver': {'id': 9, 'lat': 5.35, 'lng': -4.01},
        'vehicle': {'id': 2},
        'sidUser': {
          'firstNames': 'Jean',
          'lastName': 'Kone',
          'phoneNumber': '+2250700000000',
          'profilePhoto': 'jean-kone.jpg',
        },
      });

      expect(ride.rideId, '14');
      expect(ride.status, RideStatus.accepted);
      expect(ride.passengerName, 'Jean Kone');
      expect(ride.passengerPhone, '+2250700000000');
      expect(ride.passengerPhoto, 'jean-kone.jpg');
      expect(ride.assignedDriverId, 9);
      expect(ride.vehicleId, 2);
      expect(ride.driverLocation, isNotNull);
    });

    test('falls back to vehicle ownership to resolve assigned driver', () {
      final ride = DriverRide.fromMap({
        'id': 34,
        'statusRace': 'DRIVER_ASSIGNED',
        'estimatedPrice': 5100,
        'departureAddress': 'Cocody',
        'latDeparture': '5.3391987',
        'longDeparture': '-4.0185272',
        'arrivalAddress': 'Plateau',
        'arrivalLat': '5.3385503',
        'arrivalLong': '-3.9505716',
        'vehicle': {
          'id': 3,
          'sidUserId': 18,
          'sidUser': {'id': 99},
        },
      });

      expect(ride.assignedDriverId, 18);
    });

    test('falls back to vehicle sidUser.id when sidUserId is missing', () {
      final ride = DriverRide.fromMap({
        'id': 35,
        'statusRace': 'DRIVER_ASSIGNED',
        'departureAddress': 'Cocody',
        'latDeparture': '5.3391987',
        'longDeparture': '-4.0185272',
        'arrivalAddress': 'Plateau',
        'arrivalLat': '5.3385503',
        'arrivalLong': '-3.9505716',
        'vehicle': {
          'id': 3,
          'sidUser': {'id': 19},
        },
      });

      expect(ride.assignedDriverId, 19);
    });

    test('parses passenger rating and rides count when available', () {
      final ride = DriverRide.fromMap({
        'id': 88,
        'statusRace': 'DRIVER_ASSIGNED',
        'departureAddress': 'Cocody',
        'latDeparture': '5.3391987',
        'longDeparture': '-4.0185272',
        'arrivalAddress': 'Plateau',
        'arrivalLat': '5.3385503',
        'arrivalLong': '-3.9505716',
        'sidUser': {
          'firstNames': 'Awa',
          'lastName': 'Kone',
          'rating': '4.2',
          'coursesCount': '71',
        },
      });

      expect(ride.passengerName, 'Awa Kone');
      expect(ride.passengerRating, 4.2);
      expect(ride.passengerRidesCount, 71);
    });

    test('parses feedback received by the driver for the ride', () {
      final ride = DriverRide.fromMap({
        'id': 89,
        'statusRace': 'COMPLETED',
        'departureAddress': 'Cocody',
        'latDeparture': '5.3391987',
        'longDeparture': '-4.0185272',
        'arrivalAddress': 'Plateau',
        'arrivalLat': '5.3385503',
        'arrivalLong': '-3.9505716',
        'driverRating': 4,
        'commentDriver': 'Chauffeur ponctuel',
      });

      expect(ride.driverRatingFromPassenger, 4);
      expect(ride.driverCommentFromPassenger, 'Chauffeur ponctuel');
    });

    test('parses final metrics when backend returns strings', () {
      final ride = DriverRide.fromMap({
        'rideId': 'R-1',
        'statusRace': 'COMPLETED',
        'departureAddress': 'Adjame',
        'latDeparture': '5.3484',
        'longDeparture': '-4.0135',
        'arrivalAddress': 'Airport',
        'arrivalLat': '5.2612',
        'arrivalLong': '-3.9262',
        'finalPrice': '5650',
        'finalDistance': '12',
        'finalDuration': '27',
      });

      expect(ride.finalPrice, 5650);
      expect(ride.estimatedDistanceKm, 12);
      expect(ride.estimatedDurationMin, 27);
      expect(ride.driverLocation, isNull);
    });

    test('uses accepted, started and ended timestamps for history', () {
      final ride = DriverRide.fromMap({
        'rideId': 'R-2',
        'statusRace': 'CANCELLED',
        'departureAddress': 'Adjame',
        'latDeparture': '5.3484',
        'longDeparture': '-4.0135',
        'arrivalAddress': 'Airport',
        'arrivalLat': '5.2612',
        'arrivalLong': '-3.9262',
        'createdAt': '2026-05-08T09:00:00.000Z',
        'updatedAt': '2026-05-08T09:35:00.000Z',
        'dateAcceptance': '2026-05-08T09:05:00.000Z',
        'departureDate': '2026-05-08T09:12:00.000Z',
        'dateCancellation': '2026-05-08T09:28:00.000Z',
      });

      expect(ride.acceptedAt, DateTime.parse('2026-05-08T09:05:00.000Z'));
      expect(ride.startedAt, DateTime.parse('2026-05-08T09:12:00.000Z'));
      expect(ride.endedAt, DateTime.parse('2026-05-08T09:28:00.000Z'));
      expect(ride.cancelledAt, DateTime.parse('2026-05-08T09:28:00.000Z'));
      expect(
        ride.historyDate,
        DateTime.parse('2026-05-08T09:28:00.000Z').toLocal(),
      );
    });

    test('falls back cleanly when nested values are missing', () {
      final ride = DriverRide.fromMap({
        'rideId': 'A-1',
        'statusRace': 'PENDING',
      });

      expect(ride.rideId, 'A-1');
      expect(ride.status, RideStatus.pending);
      expect(ride.passengerName, 'Passager');
      expect(ride.pickupAddress, 'Lieu de départ');
      expect(ride.destinationAddress, 'Destination');
      expect(ride.driverLocation, isNull);
    });

    test('normalizes legacy pickup and destination ordering', () {
      final ride = DriverRide.fromMap({
        'rideId': 'A-2',
        'statusRace': 'DRIVER_ASSIGNED',
        'departureAddress': 'Cocody, Riviera 2',
        'arrivalAddress': 'Yopougon, Niangon',
      });

      expect(ride.pickupAddress, 'Riviera 2, Cocody');
      expect(ride.destinationAddress, 'Niangon, Yopougon');
    });
  });
}
