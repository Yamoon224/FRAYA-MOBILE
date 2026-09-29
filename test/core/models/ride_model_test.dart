import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';

void main() {
  group('Ride.fromMap', () {
    test('normalizes departure and arrival address order', () {
      final ride = Ride.fromMap({
        'id': 'r1',
        'departureAddress': 'Cocody, Riviera Palmeraie',
        'arrivalAddress': 'Plateau, Abidjan',
        'finalPrice': 2300,
        'createdAt': '2026-05-01T10:00:00.000Z',
        'status': 'COMPLETED',
        'requestedRange': 'MAGIC',
      });

      expect(ride.departureAddress, 'Riviera Palmeraie, Cocody');
      expect(ride.arrivalAddress, 'Plateau, Abidjan');
    });

    test('uses backend history timestamps and received passenger comment', () {
      final ride = Ride.fromMap({
        'id': 'r2',
        'departureAddress': 'Cocody',
        'arrivalAddress': 'Plateau',
        'finalPrice': 4200,
        'createdAt': '2026-05-01T09:00:00.000Z',
        'dateAcceptance': '2026-05-01T09:05:00.000Z',
        'departureDate': '2026-05-01T09:15:00.000Z',
        'dateArrival': '2026-05-01T09:42:00.000Z',
        'statusRace': 'COMPLETED',
        'requestedRange': 'MAGIC',
        'passengerComment': 'Chauffeur ponctuel',
      });

      expect(ride.acceptedAt, DateTime.parse('2026-05-01T09:05:00.000Z'));
      expect(ride.startedAt, DateTime.parse('2026-05-01T09:15:00.000Z'));
      expect(ride.endedAt, DateTime.parse('2026-05-01T09:42:00.000Z'));
      expect(ride.completedAt, DateTime.parse('2026-05-01T09:42:00.000Z'));
      expect(ride.date, DateTime.parse('2026-05-01T09:42:00.000Z'));
      expect(ride.passengerCommentFromDriver, 'Chauffeur ponctuel');
      expect(ride.driverCommentFromPassenger, isNull);
    });

    test('driverRating: 0 marks a completed ride as not yet rated', () {
      final ride = Ride.fromMap({
        'id': 'r3',
        'departureAddress': 'Cocody',
        'arrivalAddress': 'Plateau',
        'finalPrice': 2500,
        'createdAt': '2026-05-13T15:31:26.631Z',
        'dateArrival': '2026-05-13T15:36:24.162Z',
        'statusRace': 'COMPLETED',
        'requestedRange': 'MAGIC',
        'driverRating': 0,
        'passengerComment': null,
      });

      expect(ride.driverRatingFromPassenger, 0);
      expect(ride.hasRated, isFalse);
      expect(ride.canRateDriver, isTrue);
    });

    test('driverRating and commentDriver mark the ride as already rated', () {
      final ride = Ride.fromMap({
        'id': 'r4',
        'departureAddress': 'Cocody',
        'arrivalAddress': 'Plateau',
        'finalPrice': 5650,
        'createdAt': '2026-05-13T15:31:26.631Z',
        'dateArrival': '2026-05-13T15:36:24.162Z',
        'statusRace': 'COMPLETED',
        'requestedRange': 'MAGIC',
        'driverRating': 4,
        'commentDriver': 'Très bon chauffeur',
      });

      expect(ride.driverRatingFromPassenger, 4);
      expect(ride.driverCommentFromPassenger, 'Très bon chauffeur');
      expect(ride.hasRated, isTrue);
      expect(ride.canRateDriver, isFalse);
    });

    test('passagerRating (backend) maps to passengerRatingFromDriver', () {
      final ride = Ride.fromMap({
        'id': 'r5',
        'departureAddress': 'Cocody',
        'arrivalAddress': 'Plateau',
        'finalPrice': 2500,
        'createdAt': '2026-05-13T15:31:26.631Z',
        'dateArrival': '2026-05-13T15:36:24.162Z',
        'statusRace': 'COMPLETED',
        'requestedRange': 'MAGIC',
        'driverRating': 0,
        'passagerRating': 3,
        'passagerComment': 'Avis deja laisse',
      });

      expect(ride.driverRatingFromPassenger, 0);
      expect(ride.passengerRatingFromDriver, 3);
      expect(ride.passengerCommentFromDriver, 'Avis deja laisse');
      expect(ride.driverCommentFromPassenger, isNull);
      expect(ride.canRateDriver, isTrue);
    });

    test('passengerRating fallback still maps to passengerRatingFromDriver', () {
      final ride = Ride.fromMap({
        'id': 'r5b',
        'departureAddress': 'Cocody',
        'arrivalAddress': 'Plateau',
        'finalPrice': 2500,
        'createdAt': '2026-05-13T15:31:26.631Z',
        'dateArrival': '2026-05-13T15:36:24.162Z',
        'statusRace': 'COMPLETED',
        'requestedRange': 'MAGIC',
        'driverRating': 0,
        'passengerRating': 3,
        'passengerComment': 'Avis deja laisse',
      });

      expect(ride.passengerRatingFromDriver, 3);
      expect(ride.passengerCommentFromDriver, 'Avis deja laisse');
    });

    test('driverProfileRating stays null when driver has no rating field', () {
      final ride = Ride.fromMap({
        'id': 'r6',
        'departureAddress': 'Cocody',
        'arrivalAddress': 'Plateau',
        'finalPrice': 5100,
        'createdAt': '2026-05-13T15:31:26.631Z',
        'dateArrival': '2026-05-13T15:36:24.162Z',
        'statusRace': 'COMPLETED',
        'requestedRange': 'MAGIC',
        'driverRating': 0,
        'vehicle': {
          'sidUser': {'firstNames': 'Sabdy', 'lastName': 'Drivers'},
        },
      });

      expect(ride.driverProfileRating, isNull);
    });

    test('commentDriver blocks rating even when driverRating is zero', () {
      final ride = Ride.fromMap({
        'id': 'r7',
        'departureAddress': 'Cocody',
        'arrivalAddress': 'Plateau',
        'finalPrice': 5100,
        'createdAt': '2026-05-13T15:31:26.631Z',
        'dateArrival': '2026-05-13T15:36:24.162Z',
        'statusRace': 'COMPLETED',
        'requestedRange': 'MAGIC',
        'driverRating': 0,
        'passengerComment': null,
        'commentDriver': 'Passager ponctuel',
      });

      expect(ride.driverCommentFromPassenger, 'Passager ponctuel');
      expect(ride.canRateDriver, isFalse);
    });
  });
}
