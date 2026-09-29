library;

import 'driver_wallet_transaction.dart';

class DriverWalletOverview {
  const DriverWalletOverview({
    required this.balance,
    required this.transactions,
    this.walletId,
  });

  final double balance;
  final String? walletId;
  final List<DriverWalletTransaction> transactions;
}
