library;

import 'package:url_launcher/url_launcher.dart';

class PassengerContactLauncherService {
  const PassengerContactLauncherService();

  Future<bool> launchPhoneCall(String? rawPhoneNumber) async {
    final phoneNumber = normalizePhoneNumber(rawPhoneNumber);
    if (phoneNumber == null) return false;
    return launchExternal(buildPhoneCallUri(phoneNumber));
  }

  Future<bool> launchWhatsApp(String? rawPhoneNumber) async {
    final phoneNumber = normalizeWhatsAppPhoneNumber(rawPhoneNumber);
    if (phoneNumber == null) return false;
    if (await _tryLaunchExternal(buildNativeWhatsAppUri(phoneNumber))) {
      return true;
    }
    return _tryLaunchExternal(buildWhatsAppUri(phoneNumber));
  }

  String? normalizePhoneNumber(String? input, {bool digitsOnly = false}) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    if (digitsOnly) return digits;

    final hasPlusPrefix = trimmed.startsWith('+');
    return hasPlusPrefix ? '+$digits' : digits;
  }

  String? normalizeWhatsAppPhoneNumber(String? input) {
    final digits = normalizePhoneNumber(input, digitsOnly: true);
    if (digits == null) return null;
    if (digits.length == 10 && digits.startsWith('0')) return '225$digits';
    return digits;
  }

  Uri buildPhoneCallUri(String phoneNumber) {
    return Uri(scheme: 'tel', path: phoneNumber);
  }

  Uri buildWhatsAppUri(String phoneNumber) {
    return Uri.https('wa.me', '/$phoneNumber');
  }

  Uri buildNativeWhatsAppUri(String phoneNumber) {
    return Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {'phone': phoneNumber},
    );
  }

  Future<bool> canLaunch(Uri uri) => canLaunchUrl(uri);

  Future<bool> launch(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  Future<bool> launchExternal(Uri uri) async {
    if (!await canLaunch(uri)) return false;
    return launch(uri);
  }

  Future<bool> _tryLaunchExternal(Uri uri) async {
    try {
      return await launchExternal(uri);
    } catch (_) {
      return false;
    }
  }
}
