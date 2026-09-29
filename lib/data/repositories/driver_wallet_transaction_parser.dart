library;

import '../../core/utils/map_parsing_utils.dart';
import '../../domain/models/driver_wallet_transaction.dart';

class ParsedWalletTransaction {
  const ParsedWalletTransaction({
    required this.transaction,
    this.walletId,
    this.afterBalance,
    this.balance,
  });

  final DriverWalletTransaction transaction;
  final String? walletId;
  final double? afterBalance;
  final double? balance;
}

class DriverWalletTransactionParser {
  const DriverWalletTransactionParser();

  List<Map<String, dynamic>> extractEntries(dynamic payload) {
    dynamic current = payload;
    while (current is Map) {
      final next =
          current['data'] ??
          current['result'] ??
          current['items'] ??
          current['reloads'] ??
          current['transactions'];
      if (next == null || identical(next, current)) break;
      current = next;
    }
    if (current is List) {
      return current
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (current is Map<String, dynamic>) return [current];
    if (current is Map) return [Map<String, dynamic>.from(current)];
    return const <Map<String, dynamic>>[];
  }

  ParsedWalletTransaction parseTransaction(Map<String, dynamic> data) {
    final typeSignal = _buildTypeSignal(data);
    final amount = _extractAmount(data);
    final createdAt = _parseDate(
      data['createdAt'] ??
          data['updatedAt'] ??
          data['date'] ??
          data['created_at'],
    );
    final source = _firstNonEmpty([
      data['provider']?.toString(),
      data['paymentProvider']?.toString(),
      data['source']?.toString(),
      data['network']?.toString(),
    ]);
    final reference = _firstNonEmpty([
      data['reference']?.toString(),
      data['transactionId']?.toString(),
      data['paymentReference']?.toString(),
    ]);
    final walletId = _firstNonEmpty([
      data['walletId']?.toString(),
      (data['wallet'] is Map ? data['wallet']['walletId']?.toString() : null),
    ]);
    final afterBalance = toDouble(data['afterBalance'] ?? data['balanceAfter']);
    final balance = toDouble(
      data['solde'] ??
          data['balance'] ??
          (data['wallet'] is Map ? data['wallet']['solde'] : null),
    );
    final isCredit = _isCreditType(typeSignal, amount);
    final txType = _transactionType(typeSignal, isCredit);
    final subtitleParts = <String>[
      if (source != null && source.isNotEmpty) source,
      if (reference != null && reference.isNotEmpty) reference,
    ];
    final transaction = DriverWalletTransaction(
      id:
          _firstNonEmpty([
            data['id']?.toString(),
            data['ulid']?.toString(),
            '${createdAt.millisecondsSinceEpoch}-${amount.abs()}',
          ]) ??
          '${createdAt.millisecondsSinceEpoch}-${amount.abs()}',
      title: _titleForType(txType),
      subtitle: subtitleParts.isEmpty ? 'Fraya' : subtitleParts.join(' - '),
      amount: amount.abs(),
      isCredit: isCredit,
      occurredAt: createdAt,
      type: txType,
      source: source,
      reference: reference,
      walletId: walletId,
    );
    return ParsedWalletTransaction(
      transaction: transaction,
      walletId: walletId,
      afterBalance: afterBalance,
      balance: balance,
    );
  }

  DriverWalletTransactionType _transactionType(String type, bool isCredit) {
    if (_containsAny(type, _rechargeKeywords)) {
      return DriverWalletTransactionType.recharge;
    }
    if (_containsAny(type, _packageKeywords)) {
      return DriverWalletTransactionType.packagePurchase;
    }
    if (_containsAny(type, _commissionKeywords)) {
      return DriverWalletTransactionType.commission;
    }
    if (_containsAny(type, _withdrawKeywords)) {
      return DriverWalletTransactionType.withdrawal;
    }
    return isCredit
        ? DriverWalletTransactionType.recharge
        : DriverWalletTransactionType.withdrawal;
  }

  String _titleForType(DriverWalletTransactionType type) {
    switch (type) {
      case DriverWalletTransactionType.recharge:
        return 'Recharge';
      case DriverWalletTransactionType.packagePurchase:
        return 'Achat package';
      case DriverWalletTransactionType.withdrawal:
        return 'Retrait';
      case DriverWalletTransactionType.commission:
        return 'Commission Fraya';
      case DriverWalletTransactionType.other:
        return 'Transaction';
    }
  }

  bool _isCreditType(String type, double amount) {
    if (amount < 0) return false;
    if (_containsAny(type, _packageKeywords)) return false;
    if (_containsAny(type, _commissionKeywords)) return false;
    if (_containsAny(type, _withdrawKeywords) &&
        !_containsAny(type, _rechargeKeywords)) {
      return false;
    }
    return true;
  }

  String _buildTypeSignal(Map<String, dynamic> data) {
    final values = <dynamic>[
      data['type'],
      data['operationType'],
      data['kind'],
      data['status'],
      data['statut'],
      data['name'],
      data['title'],
      data['label'],
      data['description'],
      data['motif'],
      data['nature'],
    ];
    return values
        .map((raw) => raw?.toString().trim().toLowerCase() ?? '')
        .where((v) => v.isNotEmpty)
        .toSet()
        .join(' ');
  }

  double _extractAmount(Map<String, dynamic> data) {
    for (final raw in [
      data['amount'],
      data['paidAmount'],
      data['value'],
      data['montant'],
      data['netAmount'],
      data['signedAmount'],
    ]) {
      final parsed = toDouble(raw);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  bool _containsAny(String value, List<String> keywords) {
    for (final keyword in keywords) {
      if (value.contains(keyword)) return true;
    }
    return false;
  }

  DateTime _parseDate(dynamic raw) {
    return DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  static const List<String> _rechargeKeywords = [
    'recharge',
    'reload',
    'deposit',
    'depot',
    'credit',
    'topup',
    'top up',
  ];

  static const List<String> _withdrawKeywords = [
    'withdraw',
    'drawal',
    'debit',
    'retrait',
    'cashout',
    'cash out',
    'sortie',
  ];

  static const List<String> _commissionKeywords = [
    'commission',
    'fee',
    'frais',
  ];

  static const List<String> _packageKeywords = [
    'package',
    'subscription',
    'souscription',
    'forfait',
    'abonnement',
  ];
}
