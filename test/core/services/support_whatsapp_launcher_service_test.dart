import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/support_whatsapp_launcher_service.dart';

void main() {
  group('SupportWhatsAppLauncherService.buildSupportUri', () {
    test('builds wa.me uri with encoded message', () {
      final service = SupportWhatsAppLauncherService();

      final uri = service.buildSupportUri(
        phoneNumber: '2250700000000',
        message: 'Bonjour support Fraya',
      );

      expect(uri.host, 'wa.me');
      expect(uri.path, '/2250700000000');
      expect(uri.queryParameters['text'], 'Bonjour support Fraya');
    });

    test('builds native whatsapp uri with encoded message', () {
      final service = SupportWhatsAppLauncherService();

      final uri = service.buildNativeSupportUri(
        phoneNumber: '2250700000000',
        message: 'Bonjour support Fraya',
      );

      expect(uri.scheme, 'whatsapp');
      expect(uri.host, 'send');
      expect(uri.queryParameters['phone'], '2250700000000');
      expect(uri.queryParameters['text'], 'Bonjour support Fraya');
    });
  });
}
