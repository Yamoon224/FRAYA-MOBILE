library;

import '../../core/utils/map_parsing_utils.dart';

/// Paiement Orange Money initialisé côté serveur : l'utilisateur le règle dans [paymentUrl].
class OrangeMoneyPayment {
  const OrangeMoneyPayment({required this.paymentUrl, required this.reference});

  final String paymentUrl;
  final String reference;

  factory OrangeMoneyPayment.fromMap(Map<String, dynamic> map) {
    final data = nestedMap(map, ['data']) ?? map;
    return OrangeMoneyPayment(
      paymentUrl: firstString([data['paymentUrl']], fallback: ''),
      reference: firstString([data['reference']], fallback: ''),
    );
  }

  bool get isValid => paymentUrl.isNotEmpty && reference.isNotEmpty;
}

enum OrangeMoneyPaymentStatus { pending, success, failed }

OrangeMoneyPaymentStatus parseOrangeMoneyPaymentStatus(dynamic payload) {
  final map = payload is Map
      ? Map<String, dynamic>.from(payload)
      : <String, dynamic>{};
  final data = nestedMap(map, ['data']) ?? map;
  if (data['success'] == true) return OrangeMoneyPaymentStatus.success;
  final status = data['paymentStatus']?.toString().toUpperCase();
  if (status == 'SUCCESS') return OrangeMoneyPaymentStatus.success;
  if (status == 'FAILED') return OrangeMoneyPaymentStatus.failed;
  return OrangeMoneyPaymentStatus.pending;
}
