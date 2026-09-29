import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/services/push_notification_service.dart';

void main() {
  test('shares concurrent initialization requests', () async {
    AppConfig.instance.init(flavor: AppFlavor.dev);
    final service = PushNotificationService.instance;

    final firstInitialization = service.init();
    final secondInitialization = service.init();

    expect(identical(firstInitialization, secondInitialization), isTrue);
    await firstInitialization;
  });
}
