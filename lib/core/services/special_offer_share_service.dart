library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';

import '../../domain/models/special_offer.dart';
import '../config/app_config.dart';
import '../config/store_links.dart';

typedef SpecialOfferShareInvoker = Future<Object?> Function(ShareParams params);

/// Lien de téléchargement ajouté au texte partagé (null : rien à ajouter).
typedef StoreLinkResolver = String? Function();

String? _defaultStoreLink() {
  if (kIsWeb || !Platform.isAndroid) return null;
  try {
    return StoreLinks.shareLink(
      isAndroid: true,
      flavor: AppConfig.instance.flavor,
    );
  } catch (_) {
    // Configuration pas encore initialisée : on partage sans lien plutôt que d'échouer.
    return null;
  }
}

class SpecialOfferShareService {
  const SpecialOfferShareService({
    SpecialOfferShareInvoker shareInvoker = _defaultShareInvoker,
    StoreLinkResolver storeLink = _defaultStoreLink,
  }) : _shareInvoker = shareInvoker,
       _storeLink = storeLink;

  final SpecialOfferShareInvoker _shareInvoker;
  final StoreLinkResolver _storeLink;

  String buildShareText(SpecialOffer offer) {
    final base = _baseText(offer);
    final link = _storeLink();
    if (link == null || base.contains(link)) return base;
    return base.isEmpty ? link : '$base\n\n$link';
  }

  String _baseText(SpecialOffer offer) {
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
