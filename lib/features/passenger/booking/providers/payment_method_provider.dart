import 'package:flutter_riverpod/legacy.dart';

enum PaymentMethod {
  cash('CASH', 'Espèces'),
  wave('MOBILE_MONEY', 'WAVE'),
  orangeMoney('MOBILE_MONEY', 'Orange Money'),
  mtnMoney('MOBILE_MONEY', 'MTN Money'),
  moovMoney('MOBILE_MONEY', 'Moov Money');

  const PaymentMethod(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

final selectedPaymentMethodProvider = StateProvider<PaymentMethod>(
  (_) => PaymentMethod.cash,
);

