import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';

void main() {
  group('ActiveRide.fromMap', () {
    test('parses backend payload defensively with driver and vehicle data', () {
      final ride = ActiveRide.fromMap({
        'id': 14,
        'courseStatus': 'DRIVER_EN_ROUTE',
        'requestedRange': 'MAGIC',
        'finalPrice': 4500,
        'estimatedDistance': 15.2,
        'estimatedDuration': 25,
        'departureAddress': 'Adjame',
        'latDeparture': 5.3484,
        'longDeparture': -4.0135,
        'arrivalAddress': 'Airport',
        'arrivalLat': 5.2612,
        'arrivalLong': -3.9262,
        'updatedAt': '2026-05-08T10:00:00.000Z',
        'driver': {
          'firstName': 'Jean',
          'lastName': 'Kone',
          'rating': 4.9,
          'phoneNumber': '+2250700112233',
        },
        'currentDriverPosition': {'lat': 5.35, 'lng': -4.01},
        'vehicle': {
          'brand': 'Toyota',
          'model': 'Corolla',
          'licensePlate': 'AB-123-CD',
          'color': 'Blanc',
        },
      });

      expect(ride.rideId, '14');
      expect(ride.status, RideStatus.accepted);
      expect(ride.driverName, 'Jean Kone');
      expect(ride.driverPhone, '+2250700112233');
      expect(ride.carModel, 'Toyota Corolla');
      expect(ride.carPlate, 'AB-123-CD');
      expect(ride.driverLocation.latitude, 5.35);
      expect(ride.pickupAddress, 'Adjame');
      expect(ride.destinationAddress, 'Airport');
      expect(ride.arrivedAt, isNull);
    });

    test('extracts driver profile photo from vehicle sid user', () {
      final ride = ActiveRide.fromMap({
        'rideId': 'A-4',
        'statusRace': 'DRIVER_ASSIGNED',
        'vehicle': {
          'sidUser': {
            'firstNames': 'Moussa',
            'lastName': 'Traore',
            'profilePhoto': '/uploads/drivers/moussa.jpg',
          },
        },
      });

      expect(ride.driverName, 'Moussa Traore');
      expect(ride.driverPhoto, '/uploads/drivers/moussa.jpg');
    });

    test('falls back cleanly when values are missing', () {
      final ride = ActiveRide.fromMap({
        'rideId': 'A-1',
        'statusRace': 'PENDING',
      });

      expect(ride.rideId, 'A-1');
      expect(ride.status, RideStatus.pending);
      expect(ride.driverName, 'Chauffeur Fraya');
      expect(ride.pickupAddress, 'Lieu de départ');
      expect(ride.destinationAddress, 'Destination');
      expect(ride.driverRating, 4.8);
      expect(ride.driverPhoto, 'assets/images/driver_placeholder.png');
    });

    test('normalizes legacy address ordering from backend', () {
      final ride = ActiveRide.fromMap({
        'rideId': 'A-2',
        'statusRace': 'PENDING',
        'departureAddress': 'Cocody, Riviera Palmeraie',
        'arrivalAddress': 'Yopougon, Niangon',
      });

      expect(ride.pickupAddress, 'Riviera Palmeraie, Cocody');
      expect(ride.destinationAddress, 'Niangon, Yopougon');
    });

    test(
      'extracts pickup and destination place ids from direct and nested payloads',
      () {
        final ride = ActiveRide.fromMap({
          'rideId': 'A-3',
          'statusRace': 'ACCEPTED',
          'departureAddress': 'Cocody',
          'arrivalAddress': 'Plateau',
          'departurePlaceId': 'dep_place_123',
          'destination': {'place_id': 'arr_place_456'},
        });

        expect(ride.pickupPlaceId, 'dep_place_123');
        expect(ride.destinationPlaceId, 'arr_place_456');
      },
    );

    test('parses arrivedAt only when the driver is at pickup', () {
      final ride = ActiveRide.fromMap({
        'rideId': 'A-5',
        'statusRace': 'DRIVER_ARRIVED',
        'driverArrivedAt': '2026-05-08T10:15:00.000Z',
        'updatedAt': '2026-05-08T10:16:00.000Z',
      });

      expect(ride.status, RideStatus.arrived);
      expect(ride.arrivedAt, DateTime.parse('2026-05-08T10:15:00.000Z'));
    });
  });
}
