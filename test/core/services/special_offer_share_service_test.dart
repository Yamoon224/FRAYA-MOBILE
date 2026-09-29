import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/special_offer_share_service.dart';
import 'package:fraya_mobile/domain/models/special_offer.dart';

void main() {
  group('SpecialOfferShareService', () {
    test('builds the default share text from title and description', () {
      final service = SpecialOfferShareService(
        shareInvoker: (_) async => Object(),
      );

      final text = service.buildShareText(_offer());

      expect(
        text,
        'Invitez vos proches\n\nDecouvrez Fraya avec votre entourage.',
      );
    });

    test('prefers the configured share text when present', () {
      final service = SpecialOfferShareService(
        shareInvoker: (_) async => Object(),
      );

      final text = service.buildShareText(
        _offer(shareText: 'Texte marketing dedie'),
      );

      expect(text, 'Texte marketing dedie');
    });

    test('shares the offer text with the title as subject', () async {
      String? sharedText;
      String? sharedSubject;
      final service = SpecialOfferShareService(
        shareInvoker: (params) async {
          sharedText = params.text;
          sharedSubject = params.subject;
          return null;
        },
      );

      await service.shareOffer(_offer());

      expect(
        sharedText,
        'Invitez vos proches\n\nDecouvrez Fraya avec votre entourage.',
      );
      expect(sharedSubject, 'Invitez vos proches');
    });
  });
}

SpecialOffer _offer({String? shareText}) {
  return SpecialOffer(
    id: 'offer-1',
    title: 'Invitez vos proches',
    description: 'Decouvrez Fraya avec votre entourage.',
    isActive: true,
    audiences: const {
      SpecialOfferAudience.passenger,
      SpecialOfferAudience.driver,
    },
    shareText: shareText,
  );
}
