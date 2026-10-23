import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/config/store_links.dart';
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

    test('ajoute le lien Play Store passager au texte partagé sur Android', () {
      final service = SpecialOfferShareService(
        shareInvoker: (_) async => Object(),
        storeLink: () =>
            StoreLinks.shareLink(isAndroid: true, flavor: AppFlavor.passenger),
      );

      expect(
        service.buildShareText(_offer()),
        'Invitez vos proches\n\nDecouvrez Fraya avec votre entourage.\n\n'
        'https://play.google.com/store/apps/details?id=fraya.taxi.ci',
      );
    });

    test(
      'ajoute le lien Play Store chauffeur pour l application chauffeur',
      () {
        final service = SpecialOfferShareService(
          shareInvoker: (_) async => Object(),
          storeLink: () =>
              StoreLinks.shareLink(isAndroid: true, flavor: AppFlavor.driver),
        );

        expect(
          service.buildShareText(_offer(shareText: 'Texte marketing dedie')),
          'Texte marketing dedie\n\n'
          'https://play.google.com/store/apps/details?id=fraya.taxi.driver.ci',
        );
      },
    );

    test('n ajoute pas le lien deux fois', () {
      final service = SpecialOfferShareService(
        shareInvoker: (_) async => Object(),
        storeLink: () => StoreLinks.passengerAndroid,
      );

      final text = service.buildShareText(
        _offer(shareText: 'Installez : ${StoreLinks.passengerAndroid}'),
      );

      expect(text, 'Installez : ${StoreLinks.passengerAndroid}');
    });
  });

  group('StoreLinks.shareLink', () {
    test('un lien par application sur Android, aucun ailleurs', () {
      expect(
        StoreLinks.shareLink(isAndroid: true, flavor: AppFlavor.passenger),
        StoreLinks.passengerAndroid,
      );
      expect(
        StoreLinks.shareLink(isAndroid: true, flavor: AppFlavor.driver),
        StoreLinks.driverAndroid,
      );
      expect(
        StoreLinks.shareLink(isAndroid: true, flavor: AppFlavor.dev),
        isNull,
      );
      expect(
        StoreLinks.shareLink(isAndroid: false, flavor: AppFlavor.passenger),
        isNull,
      );
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
