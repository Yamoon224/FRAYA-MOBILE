import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/push_notification_service.dart';

String _resolve({
  bool passenger = false,
  bool driver = false,
  bool ios = false,
  Map<String, String> env = const {},
}) => PushNotificationService.resolveOneSignalAppId(
  isPassenger: passenger,
  isDriver: driver,
  isIOS: ios,
  env: env,
);

void main() {
  const env = {
    'ONESIGNAL_APP_ID_PASSENGER': 'commun-passager',
    'ONESIGNAL_APP_ID_DRIVER': 'commun-chauffeur',
    'ONESIGNAL_APP_ID_PASSENGER_IOS': 'ios-passager',
    'ONESIGNAL_APP_ID_DRIVER_IOS': 'ios-chauffeur',
  };

  test('Android garde les identifiants communs', () {
    expect(_resolve(passenger: true, env: env), 'commun-passager');
    expect(_resolve(driver: true, env: env), 'commun-chauffeur');
  });

  test('iPhone utilise l\'application OneSignal propre à chaque app', () {
    expect(_resolve(passenger: true, ios: true, env: env), 'ios-passager');
    expect(_resolve(driver: true, ios: true, env: env), 'ios-chauffeur');
  });

  test('iPhone retombe sur l\'identifiant commun quand celui d\'iOS manque ou est vide', () {
    final partial = {...env, 'ONESIGNAL_APP_ID_DRIVER_IOS': '  '}..remove('ONESIGNAL_APP_ID_PASSENGER_IOS');

    expect(_resolve(passenger: true, ios: true, env: partial), 'commun-passager');
    expect(_resolve(driver: true, ios: true, env: partial), 'commun-chauffeur');
  });

  test('espaces ignorés, et rien sans type d\'application', () {
    expect(_resolve(passenger: true, ios: true, env: {'ONESIGNAL_APP_ID_PASSENGER_IOS': ' ios-passager '}), 'ios-passager');
    expect(_resolve(env: env), '');
    expect(_resolve(passenger: true, env: const {}), '');
  });
}
