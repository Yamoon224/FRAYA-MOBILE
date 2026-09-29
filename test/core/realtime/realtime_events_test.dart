import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/realtime/realtime_events.dart';

void main() {
  group('NearbyDriverMovingEvent.tryParse', () {
    test('parses valid payload', () {
      final event = NearbyDriverMovingEvent.tryParse({
        'driverId': 12,
        'latitude': 5.4,
        'longitude': -4.01,
        'bearing': 90,
        'vehicleColor': 'Rouge',
      });

      expect(event, isNotNull);
      expect(event!.driverId, '12');
      expect(event.latitude, 5.4);
      expect(event.longitude, -4.01);
      expect(event.bearing, 90);
      expect(event.vehicleColorRaw, 'Rouge');
    });

    test('returns null when coordinates are missing', () {
      final event = NearbyDriverMovingEvent.tryParse({'driverId': '3'});
      expect(event, isNull);
    });
  });

  group('RidePositionUpdateEvent.tryParse', () {
    test('parses ride position payload', () {
      final event = RidePositionUpdateEvent.tryParse({
        'rideId': 77,
        'driverLat': 5.35,
        'driverLng': -4.02,
      });

      expect(event, isNotNull);
      expect(event!.rideId, '77');
      expect(event.latitude, 5.35);
      expect(event.longitude, -4.02);
    });
  });

  group('RideAcceptedEvent.tryParse', () {
    test('parses accepted payload', () {
      final event = RideAcceptedEvent.tryParse({
        'rideId': 'abc-123',
        'passengerId': 90,
      });

      expect(event, isNotNull);
      expect(event!.rideId, 'abc-123');
      expect(event.passengerId, 90);
    });

    test('returns null without rideId', () {
      final event = RideAcceptedEvent.tryParse({'message': 'ok'});
      expect(event, isNull);
    });
  });

  group('DriverRideStatusRealtimeEvent.tryParse', () {
    test('parses cancelled status payload', () {
      final event = DriverRideStatusRealtimeEvent.tryParse({
        'rideId': 88,
        'status': 'CANCELLED',
        'updatedAt': '2026-05-22T12:00:00.000Z',
        'reason': 'Client a annule',
      });

      expect(event, isNotNull);
      expect(event!.rideId, '88');
      expect(event.isCancelled, isTrue);
      expect(event.reason, 'Client a annule');
    });

    test('parses cancelled statusRace payload', () {
      final event = DriverRideStatusRealtimeEvent.tryParse({
        'courseId': 99,
        'statusRace': 'CANCELLED',
        'timestamp': '2026-05-22T12:05:00.000Z',
      });

      expect(event, isNotNull);
      expect(event!.rideId, '99');
      expect(event.isCancelled, isTrue);
    });

    test('parses nested passenger cancellation without explicit status', () {
      final event = DriverRideStatusRealtimeEvent.tryParse({
        'data': {
          'course': {
            'courseId': 101,
            'cancelledBy': 'PASSENGER',
            'reason': 'Changement de programme',
          },
        },
      }, fallbackStatus: 'CANCELLED');

      expect(event, isNotNull);
      expect(event!.rideId, '101');
      expect(event.isCancelled, isTrue);
      expect(event.changeActor, RideChangeActor.passenger);
      expect(event.reason, 'Changement de programme');
    });

    test('normalizes nested driver cancellation actor aliases', () {
      final event = DriverRideStatusRealtimeEvent.tryParse({
        'ride': {'rideId': 'ride-driver-1', 'actor': 'chauffeur'},
      }, fallbackStatus: 'CANCELLED');

      expect(event, isNotNull);
      expect(event!.changeActor, RideChangeActor.driver);
    });

    test('returns null without rideId/status', () {
      final event = DriverRideStatusRealtimeEvent.tryParse({'foo': 'bar'});
      expect(event, isNull);
    });
  });

  group('NewRideOfferEvent.tryParse', () {
    test('parses ride notification payload with nested data', () {
      final event = NewRideOfferEvent.tryParse({
        'type': 'new_ride_available',
        'data': {'courseId': 123},
      });

      expect(event, isNotNull);
      expect(event!.rideId, '123');
    });

    test('parses ride notification payload when only rideId is present', () {
      final event = NewRideOfferEvent.tryParse({'rideId': 'R-77'});

      expect(event, isNotNull);
      expect(event!.rideId, 'R-77');
    });

    test('returns null for unrelated typed notifications', () {
      final event = NewRideOfferEvent.tryParse({
        'type': 'ride_cancelled',
        'rideId': 'R-77',
      });

      expect(event, isNull);
    });

    test('returns null without ride id', () {
      final event = NewRideOfferEvent.tryParse({
        'type': 'new_ride_available',
        'message': 'Nouvelle course disponible',
      });

      expect(event, isNull);
    });
  });
}
