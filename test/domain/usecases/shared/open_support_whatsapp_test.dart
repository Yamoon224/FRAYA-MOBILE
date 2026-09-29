import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/support_whatsapp_launcher_service.dart';
import 'package:fraya_mobile/domain/usecases/shared/open_support_whatsapp.dart';

class _FakeSupportWhatsAppLauncherService
    extends SupportWhatsAppLauncherService {
  _FakeSupportWhatsAppLauncherService(this.result);

  final bool result;

  @override
  Future<bool> openSupportChat({
    required String rawPhoneNumber,
    required String message,
  }) async {
    return result;
  }
}

void main() {
  group('OpenSupportWhatsAppUseCase', () {
    test('returns success when WhatsApp opens', () async {
      final useCase = OpenSupportWhatsAppUseCase(
        _FakeSupportWhatsAppLauncherService(true),
      );

      final result = await useCase(
        const OpenSupportWhatsAppParams(
          phoneNumber: '2250700000000',
          message: 'Bonjour',
        ),
      );

      expect(result.isRight(), isTrue);
    });

    test('returns failure when WhatsApp cannot open', () async {
      final useCase = OpenSupportWhatsAppUseCase(
        _FakeSupportWhatsAppLauncherService(false),
      );

      final result = await useCase(
        const OpenSupportWhatsAppParams(
          phoneNumber: '2250700000000',
          message: 'Bonjour',
        ),
      );

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((failure) => failure.message, (_) => ''),
        'Impossible d\'ouvrir WhatsApp sur cet appareil.',
      );
    });
  });
}
