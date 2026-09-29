library;

import 'package:share_plus/share_plus.dart';

typedef RideTrackingShareInvoker = Future<ShareResult> Function(
  ShareParams params,
);

enum RideTrackingShareStatus { success, dismissed, unavailable }

class RideTrackingShareService {
  const RideTrackingShareService({
    RideTrackingShareInvoker shareInvoker = _defaultShareInvoker,
  }) : _shareInvoker = shareInvoker;

  static const shareSubject = 'Suivi de ma course Fraya';

  final RideTrackingShareInvoker _shareInvoker;

  String buildShareText(String url) {
    return 'Je partage ma course Fraya avec vous.\n'
        'Suivez mon trajet en temps reel ici : $url';
  }

  Future<RideTrackingShareStatus> shareTrackingLink(String url) async {
    final result = await _shareInvoker(
      ShareParams(text: buildShareText(url), subject: shareSubject),
    );
    switch (result.status) {
      case ShareResultStatus.success:
        return RideTrackingShareStatus.success;
      case ShareResultStatus.dismissed:
        return RideTrackingShareStatus.dismissed;
      case ShareResultStatus.unavailable:
        return RideTrackingShareStatus.unavailable;
    }
  }
}

Future<ShareResult> _defaultShareInvoker(ShareParams params) {
  return SharePlus.instance.share(params);
}
