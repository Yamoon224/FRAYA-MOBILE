import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/push_notification_service.dart';

void main() {
  group('PushNotificationPayload.fromData', () {
    test('parses typed ride payload values', () {
      final payload = PushNotificationPayload.fromData(
        title: 'Course acceptee',
        body: 'Votre chauffeur arrive',
        rawData: {
          'notificationId': 'notif-1',
          'data': {
            'type': 'ride_accepted',
            'rideId': 123,
            'driverId': '45',
            'recipientRole': 'passenger',
            'finalPrice': '2500',
          },
        },
      );

      expect(payload.type, 'ride_accepted');
      expect(payload.isSupported, isTrue);
      expect(payload.rideId, '123');
      expect(payload.driverId, '45');
      expect(payload.recipientRole, 'PASSENGER');
      expect(payload.finalPrice, 2500);
      expect(payload.notificationId, 'notif-1');
      expect(payload.title, 'Course acceptee');
    });

    test('parses rating and coordinates', () {
      final payload = PushNotificationPayload.fromData(
        rawData: {
          'type': 'drivers_nearby',
          'driverId': 45,
          'latitude': '5.3599517',
          'longitude': -4.0082563,
          'rating': '5',
        },
      );

      expect(payload.type, 'drivers_nearby');
      expect(payload.driverId, '45');
      expect(payload.latitude, 5.3599517);
      expect(payload.longitude, -4.0082563);
      expect(payload.rating, 5);
    });

    test('falls back to pushType and ignores unsupported type', () {
      final payload = PushNotificationPayload.fromData(
        rawData: {'pushType': 'UNKNOWN_EVENT', 'rideId': '77'},
      );

      expect(payload.type, 'unknown_event');
      expect(payload.isSupported, isFalse);
      expect(payload.rideId, '77');
    });

    test('does not treat ride id as notification id', () {
      final payload = PushNotificationPayload.fromData(
        rawData: {'type': 'ride_cancelled', 'id': 88},
      );

      expect(payload.rideId, '88');
      expect(payload.notificationId, isNull);
    });
  });
}
