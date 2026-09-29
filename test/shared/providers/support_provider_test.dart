import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/support_whatsapp_launcher_service.dart';
import 'package:fraya_mobile/domain/usecases/shared/open_support_whatsapp.dart';
import 'package:fraya_mobile/shared/models/support_topic.dart';
import 'package:fraya_mobile/shared/providers/support_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _NoopSupportWhatsAppLauncherService
    extends SupportWhatsAppLauncherService {
  @override
  Future<bool> openSupportChat({
    required String rawPhoneNumber,
    required String message,
  }) async {
    return true;
  }
}

void main() {
  group('support topics', () {
    test('exposes passenger support topics', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final topics = container.read(
        supportTopicsProvider(SupportAudience.passenger),
      );

      expect(topics.map((topic) => topic.id), ['ride', 'ride-payment']);
    });

    test('exposes driver support topics including wallet and kyc', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final topics = container.read(
        supportTopicsProvider(SupportAudience.driver),
      );

      expect(topics.map((topic) => topic.id), contains('wallet-reload'));
      expect(topics.map((topic) => topic.id), contains('kyc-rejected'));
    });
  });

  group('SupportController.buildMessage', () {
    test('includes topic, app and role labels', () {
      final controller = SupportController(
        OpenSupportWhatsAppUseCase(_NoopSupportWhatsAppLauncherService()),
      );

      final message = controller.buildMessage(
        audience: SupportAudience.driver,
        topic: SupportTopics.driver.first,
      );

      expect(message, contains('Une course'));
      expect(message, contains('Fraya Chauffeur'));
      expect(message, contains('Chauffeur'));
    });
  });
}
