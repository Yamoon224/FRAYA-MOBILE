import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/ride_tracking_share_service.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  group('RideTrackingShareService', () {
    test('builds the expected generic message', () {
      const service = RideTrackingShareService();

      final text = service.buildShareText('https://example.com/ride');

      expect(
        text,
        'Je partage ma course Fraya avec vous.\n'
        'Suivez mon trajet en temps reel ici : https://example.com/ride',
      );
    });

    test('shares the tracking link with the expected subject', () async {
      String? sharedText;
      String? sharedSubject;
      final service = RideTrackingShareService(
        shareInvoker: (params) async {
          sharedText = params.text;
          sharedSubject = params.subject;
          return const ShareResult('', ShareResultStatus.success);
        },
      );

      final result = await service.shareTrackingLink('https://example.com/42');

      expect(result, RideTrackingShareStatus.success);
      expect(
        sharedText,
        'Je partage ma course Fraya avec vous.\n'
        'Suivez mon trajet en temps reel ici : https://example.com/42',
      );
      expect(sharedSubject, RideTrackingShareService.shareSubject);
    });

    test('maps dismissed and unavailable results', () async {
      var callIndex = 0;
      final service = RideTrackingShareService(
        shareInvoker: (_) async {
          callIndex++;
          if (callIndex == 1) {
            return const ShareResult('', ShareResultStatus.dismissed);
          }
          return ShareResult.unavailable;
        },
      );

      final dismissed = await service.shareTrackingLink('https://example.com');
      final unavailable = await service.shareTrackingLink(
        'https://example.com',
      );

      expect(dismissed, RideTrackingShareStatus.dismissed);
      expect(unavailable, RideTrackingShareStatus.unavailable);
    });
  });
}
