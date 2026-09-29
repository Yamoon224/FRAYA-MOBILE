library;

import '../../core/utils/map_parsing_utils.dart';

class DriverWalletPackageSubscriptionResult {
  const DriverWalletPackageSubscriptionResult({
    required this.message,
    this.previousBalance,
    this.newBalance,
    this.amountDebited,
    this.transactionReference,
    this.subscriptionId,
    this.packageName,
    this.subscribedAt,
  });

  final String message;
  final double? previousBalance;
  final double? newBalance;
  final double? amountDebited;
  final String? transactionReference;
  final int? subscriptionId;
  final String? packageName;
  final DateTime? subscribedAt;

  factory DriverWalletPackageSubscriptionResult.fromMap(
    Map<String, dynamic> map,
  ) {
    final data = nestedMap(map, ['data']) ?? map;
    final wallet = nestedMap(data, ['wallet']) ?? const <String, dynamic>{};
    final subscription =
        nestedMap(data, ['subscription']) ?? const <String, dynamic>{};
    final package = nestedMap(subscription, ['package']);
    return DriverWalletPackageSubscriptionResult(
      message: firstString([
        map['message'],
        data['message'],
      ], fallback: 'Souscription au package effectuee avec succes.'),
      previousBalance: toDouble(wallet['previousBalance']),
      newBalance: toDouble(wallet['newBalance']),
      amountDebited: toDouble(wallet['amountDebited']),
      transactionReference: firstString([
        wallet['transactionReference'],
        subscription['reference'],
      ], fallback: ''),
      subscriptionId: toInt(subscription['id']),
      packageName: firstString([
        package?['name'],
        subscription['packageName'],
      ], fallback: ''),
      subscribedAt: _toDate(subscription['subscribedAt']),
    );
  }
}

DateTime? _toDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
