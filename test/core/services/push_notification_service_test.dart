import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/push_notification_service.dart';

void main() {
  group('decodeFcmData', () {
    test('garde les chaînes simples et décode les structures JSON', () {
      final decoded = decodeFcmData({
        'type': 'new_ride_available',
        'rideId': '42',
        'data': '{"driverId":7,"nested":{"a":1}}',
        'list': '[1,2]',
      });

      expect(decoded['type'], 'new_ride_available');
      expect(decoded['rideId'], '42');
      expect(decoded['data'], {
        'driverId': 7,
        'nested': {'a': 1},
      });
      expect(decoded['list'], [1, 2]);
    });

    test('garde tel quel un texte qui commence par une accolade', () {
      expect(decodeFcmData({'note': '{pas du json'})['note'], '{pas du json');
    });

    test('accepte une donnée absente', () {
      expect(decodeFcmData(null), isEmpty);
    });
  });

  group('payloadFromFcm', () {
    test('mappe une notification de course acceptée', () {
      final payload = PushNotificationService.payloadFromFcm(
        title: ' Course acceptée ',
        body: 'Votre chauffeur arrive',
        data: {
          'type': 'Ride_Accepted',
          'rideId': '123',
          'driverId': '9',
          'recipientRole': 'passenger',
          'finalPrice': '2500.5',
          'rating': '5',
        },
      );

      expect(payload.type, 'ride_accepted');
      expect(payload.isSupported, isTrue);
      expect(payload.title, 'Course acceptée');
      expect(payload.body, 'Votre chauffeur arrive');
      expect(payload.rideId, '123');
      expect(payload.driverId, '9');
      expect(payload.recipientRole, 'PASSENGER');
      expect(payload.finalPrice, 2500.5);
      expect(payload.rating, 5);
    });

    test('lit les champs placés dans un data JSON imbriqué', () {
      final payload = PushNotificationService.payloadFromFcm(
        data: {
          'type': 'ride_cancelled',
          'data':
              '{"rideId":55,"cancelledBy":"DRIVER","latitude":5.3,"longitude":-4.0}',
        },
      );

      expect(payload.rideId, '55');
      expect(payload.cancelledBy, 'DRIVER');
      expect(payload.latitude, 5.3);
      expect(payload.longitude, -4.0);
    });

    test('un type inconnu n est pas pris en charge', () {
      final payload = PushNotificationService.payloadFromFcm(
        data: {'type': 'promo'},
      );

      expect(payload.isSupported, isFalse);
    });

    test('sans données : titre et corps conservés', () {
      final payload = PushNotificationService.payloadFromFcm(
        title: 'Bonjour',
        body: 'Test',
      );

      expect(payload.type, isNull);
      expect(payload.title, 'Bonjour');
      expect(payload.rawData, isNull);
    });
  });

  test('le jeton n est pas disponible avant l initialisation', () {
    final service = PushNotificationService.instance;

    expect(service.currentSubscriptionId, isNull);
    expect(service.hasNotificationPermission, isFalse);
    expect(service.isPushSubscriptionOptedIn, isFalse);
  });
}
