library;

import 'package:flutter/material.dart';

enum DriverRidePaymentMethod {
  cash('CASH', 'Especes', Icons.payments_outlined),
  mobileMoney('MOBILE_MONEY', 'Mobile Money', Icons.smartphone_rounded),
  bankCard('BANK_CARD', 'Carte bancaire', Icons.credit_card_rounded);

  const DriverRidePaymentMethod(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;
}
