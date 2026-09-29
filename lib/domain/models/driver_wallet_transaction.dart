library;

enum DriverWalletTransactionType {
  recharge,
  packagePurchase,
  withdrawal,
  commission,
  other,
}

class DriverWalletTransaction {
  const DriverWalletTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    required this.occurredAt,
    required this.type,
    this.source,
    this.reference,
    this.walletId,
  });

  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
  final DateTime occurredAt;
  final DriverWalletTransactionType type;
  final String? source;
  final String? reference;
  final String? walletId;
}
