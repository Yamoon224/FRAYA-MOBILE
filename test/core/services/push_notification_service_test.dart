import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/services/push_notification_service.dart';

void main() {
  test('shares concurrent initialization requests', () async {
    // Sans App ID OneSignal, l'initialisation s'arrête tôt : pas de SDK natif.
    dotenv.loadFromString(envString: 'ONESIGNAL_TEST=');
    AppConfig.instance.init(flavor: AppFlavor.dev);
    final service = PushNotificationService.instance;

    final firstInitialization = service.init();
    final secondInitialization = service.init();

    expect(identical(firstInitialization, secondInitialization), isTrue);
    await firstInitialization;
  });
}
