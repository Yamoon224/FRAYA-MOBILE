library;

import 'package:share_plus/share_plus.dart';

import '../../domain/models/special_offer.dart';

typedef SpecialOfferShareInvoker = Future<Object?> Function(ShareParams params);

class SpecialOfferShareService {
  const SpecialOfferShareService({
    SpecialOfferShareInvoker shareInvoker = _defaultShareInvoker,
  }) : _shareInvoker = shareInvoker;

  final SpecialOfferShareInvoker _shareInvoker;

  String buildShareText(SpecialOffer offer) {
    final customText = offer.resolvedShareText;
    if (customText != null) return customText;
    if (offer.description.isEmpty) return offer.title;
    return '${offer.title}\n\n${offer.description}'.trim();
  }

  Future<void> shareOffer(SpecialOffer offer) async {
    final title = offer.title.trim();
    await _shareInvoker(
      ShareParams(
        text: buildShareText(offer),
        subject: title.isEmpty ? null : title,
      ),
    );
  }
}

Future<Object?> _defaultShareInvoker(ShareParams params) {
  return SharePlus.instance.share(params);
}
