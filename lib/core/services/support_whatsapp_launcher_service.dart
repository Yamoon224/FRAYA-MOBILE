library;

import 'passenger_contact_launcher_service.dart';

class SupportWhatsAppLauncherService {
  SupportWhatsAppLauncherService({
    PassengerContactLauncherService? contactLauncherService,
  }) : _contactLauncherService =
           contactLauncherService ?? const PassengerContactLauncherService();

  final PassengerContactLauncherService _contactLauncherService;

  Future<bool> openSupportChat({
    required String rawPhoneNumber,
    required String message,
  }) async {
    final phoneNumber = _contactLauncherService.normalizeWhatsAppPhoneNumber(
      rawPhoneNumber,
    );
    if (phoneNumber == null) return false;
    final nativeUri = buildNativeSupportUri(
      phoneNumber: phoneNumber,
      message: message,
    );
    final webUri = buildSupportUri(phoneNumber: phoneNumber, message: message);
    if (await _tryLaunch(nativeUri)) return true;
    return _tryLaunch(webUri);
  }

  Uri buildSupportUri({required String phoneNumber, required String message}) {
    final trimmedMessage = message.trim();
    return Uri.https(
      'wa.me',
      '/$phoneNumber',
      trimmedMessage.isEmpty ? null : {'text': trimmedMessage},
    );
  }

  Uri buildNativeSupportUri({
    required String phoneNumber,
    required String message,
  }) {
    final trimmedMessage = message.trim();
    return Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {
        'phone': phoneNumber,
        if (trimmedMessage.isNotEmpty) 'text': trimmedMessage,
      },
    );
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await _contactLauncherService.launch(uri);
    } catch (_) {
      return false;
    }
  }
}
