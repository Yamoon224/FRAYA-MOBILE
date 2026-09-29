import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/passenger_contact_launcher_service.dart';

void main() {
  group('PassengerContactLauncherService', () {
    test('normalizes phone numbers with and without plus prefix', () {
      final service = const PassengerContactLauncherService();

      expect(
        service.normalizePhoneNumber(' +225 07 00 11 22 33 '),
        '+2250700112233',
      );
      expect(service.normalizePhoneNumber('07 00 11 22 33'), '0700112233');
      expect(
        service.normalizePhoneNumber('(+225) 07-00-11-22-33', digitsOnly: true),
        '2250700112233',
      );
      expect(
        service.normalizeWhatsAppPhoneNumber('07 00 11 22 33'),
        '2250700112233',
      );
      expect(
        service.normalizeWhatsAppPhoneNumber('+225 07 00 11 22 33'),
        '2250700112233',
      );
      expect(service.normalizePhoneNumber('   '), isNull);
    });

    test('builds tel and WhatsApp URIs', () {
      final service = const PassengerContactLauncherService();

      final phoneUri = service.buildPhoneCallUri('+2250700112233');
      final nativeWhatsAppUri = service.buildNativeWhatsAppUri('2250700112233');
      final whatsappUri = service.buildWhatsAppUri('2250700112233');

      expect(phoneUri.toString(), 'tel:+2250700112233');
      expect(nativeWhatsAppUri.scheme, 'whatsapp');
      expect(nativeWhatsAppUri.host, 'send');
      expect(nativeWhatsAppUri.queryParameters['phone'], '2250700112233');
      expect(whatsappUri.toString(), 'https://wa.me/2250700112233');
    });

    test(
      'launchPhoneCall and launchWhatsApp use external launch flow',
      () async {
        final service = _FakePassengerContactLauncherService(
          canLaunchResult: true,
        );

        final callResult = await service.launchPhoneCall('+2250700112233');
        final whatsAppResult = await service.launchWhatsApp('+2250700112233');

        expect(callResult, isTrue);
        expect(whatsAppResult, isTrue);
        expect(service.launchedUris, hasLength(2));
        expect(service.launchedUris.first.scheme, 'tel');
        expect(service.launchedUris.last.scheme, 'whatsapp');
        expect(
          service.launchedUris.last.queryParameters['phone'],
          '2250700112233',
        );
      },
    );

    test('falls back to wa.me when native WhatsApp cannot launch', () async {
      final service = _FakePassengerContactLauncherService(
        canLaunchUri: (uri) => uri.scheme != 'whatsapp',
      );

      final whatsAppResult = await service.launchWhatsApp('0700112233');

      expect(whatsAppResult, isTrue);
      expect(service.launchedUris, hasLength(1));
      expect(service.launchedUris.single.host, 'wa.me');
      expect(service.launchedUris.single.path, '/2250700112233');
    });

    test('returns false when target app cannot be launched', () async {
      final service = _FakePassengerContactLauncherService(
        canLaunchResult: false,
      );

      expect(await service.launchPhoneCall('+2250700112233'), isFalse);
      expect(await service.launchWhatsApp('+2250700112233'), isFalse);
      expect(service.launchedUris, isEmpty);
    });
  });
}

class _FakePassengerContactLauncherService
    extends PassengerContactLauncherService {
  _FakePassengerContactLauncherService({
    bool? canLaunchResult,
    bool Function(Uri uri)? canLaunchUri,
  }) : _canLaunchResult = canLaunchResult,
       _canLaunchUri = canLaunchUri;

  final bool? _canLaunchResult;
  final bool Function(Uri uri)? _canLaunchUri;
  final List<Uri> launchedUris = <Uri>[];

  @override
  Future<bool> canLaunch(Uri uri) async {
    return _canLaunchUri?.call(uri) ?? _canLaunchResult ?? false;
  }

  @override
  Future<bool> launch(Uri uri) async {
    launchedUris.add(uri);
    return true;
  }
}
