import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/orange_money_payment.dart';

void main() {
  group('OrangeMoneyPayment.fromMap', () {
    test('reads the backend initialize response', () {
      final payment = OrangeMoneyPayment.fromMap({
        'success': true,
        'statusCode': 200,
        'message': 'Paiement initialisé avec succès',
        'data': {
          'paymentUrl': 'https://webpayment.orange.test/pay/abc',
          'payToken': 'pay-token',
          'reference': 'FRAYA_OM_1719000000000_A1B2C3D4',
        },
      });

      expect(payment.paymentUrl, 'https://webpayment.orange.test/pay/abc');
      expect(payment.reference, 'FRAYA_OM_1719000000000_A1B2C3D4');
      expect(payment.isValid, isTrue);
    });

    test('is invalid without a payment url or reference', () {
      expect(OrangeMoneyPayment.fromMap({'data': {}}).isValid, isFalse);
      expect(
        OrangeMoneyPayment.fromMap({
          'data': {'paymentUrl': 'https://x', 'reference': ''},
        }).isValid,
        isFalse,
      );
    });
  });

  group('parseOrangeMoneyPaymentStatus', () {
    Map<String, dynamic> verify(bool success, String status) => {
      'success': true,
      'data': {'reference': 'R', 'success': success, 'paymentStatus': status},
    };

    test('maps the verify response', () {
      expect(
        parseOrangeMoneyPaymentStatus(verify(true, 'SUCCESS')),
        OrangeMoneyPaymentStatus.success,
      );
      expect(
        parseOrangeMoneyPaymentStatus(verify(false, 'FAILED')),
        OrangeMoneyPaymentStatus.failed,
      );
      expect(
        parseOrangeMoneyPaymentStatus(verify(false, 'PENDING')),
        OrangeMoneyPaymentStatus.pending,
      );
    });

    test(
      'treats unknown or malformed payloads as pending, never as success',
      () {
        expect(
          parseOrangeMoneyPaymentStatus(null),
          OrangeMoneyPaymentStatus.pending,
        );
        expect(
          parseOrangeMoneyPaymentStatus('oops'),
          OrangeMoneyPaymentStatus.pending,
        );
        expect(
          parseOrangeMoneyPaymentStatus({
            'success': false,
            'message': 'Aucune transaction trouvée pour cette référence',
          }),
          OrangeMoneyPaymentStatus.pending,
        );
      },
    );
  });
}
