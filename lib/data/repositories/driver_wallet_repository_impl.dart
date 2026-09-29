library;

import '../../domain/models/driver_wallet_overview.dart';
import '../../domain/models/driver_wallet_package.dart';
import '../../domain/models/driver_wallet_package_subscription_result.dart';
import '../../domain/models/driver_wallet_reload_result.dart';
import '../../domain/repositories/driver_wallet_repository.dart';
import '../sources/remote/driver_wallet_remote_data_source.dart';
import 'driver_wallet_transaction_parser.dart';

class DriverWalletRepositoryImpl implements DriverWalletRepository {
  DriverWalletRepositoryImpl({
    required DriverWalletRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final DriverWalletRemoteDataSource _remoteDataSource;
  static const _parser = DriverWalletTransactionParser();

  @override
  Future<DriverWalletOverview> fetchWalletOverview() async {
    final payload = await _remoteDataSource.getReloads();
    final entries = _parser.extractEntries(payload);
    final parsed = entries.map(_parser.parseTransaction).toList()
      ..sort(
        (a, b) => b.transaction.occurredAt.compareTo(a.transaction.occurredAt),
      );

    final deduped = <String, ParsedWalletTransaction>{};
    for (final item in parsed) {
      final ref = item.transaction.reference;
      final key = (ref != null && ref.isNotEmpty) ? ref : item.transaction.id;
      deduped.putIfAbsent(key, () => item);
    }
    final dedupedList = deduped.values.toList()
      ..sort(
        (a, b) => b.transaction.occurredAt.compareTo(a.transaction.occurredAt),
      );

    final transactions = dedupedList.map((item) => item.transaction).toList();
    final walletId = _firstNonEmpty(
      dedupedList.map((item) => item.walletId).whereType<String>().toList(),
    );
    final explicitBalance = dedupedList
        .map((item) => item.afterBalance ?? item.balance)
        .whereType<double>()
        .cast<double?>()
        .firstWhere((value) => value != null, orElse: () => null);
    final computedBalance = transactions.fold<double>(0, (sum, tx) {
      return sum + (tx.isCredit ? tx.amount : -tx.amount);
    });

    return DriverWalletOverview(
      balance: explicitBalance ?? computedBalance,
      walletId: walletId,
      transactions: transactions,
    );
  }

  @override
  Future<List<DriverWalletPackage>> fetchPackages() async {
    final payload = await _remoteDataSource.getPackages();
    final entries = _extractList(payload);
    return entries
        .map((item) => DriverWalletPackage.fromMap(item))
        .where((item) => item.isVisible)
        .toList();
  }

  @override
  Future<DriverWalletPackageSubscriptionResult> subscribeToPackage({
    required int sidUserId,
    required int packageId,
  }) async {
    final payload = await _remoteDataSource.subscribeToPackage(
      sidUserId: sidUserId,
      packageId: packageId,
    );
    final map = payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};
    return DriverWalletPackageSubscriptionResult.fromMap(map);
  }

  @override
  Future<DriverWalletReloadResult> reloadWallet({
    required double amount,
    String? walletId,
  }) async {
    final payload = await _remoteDataSource.reloadWallet(
      amount: amount,
      walletId: walletId,
    );
    final map = payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};
    return DriverWalletReloadResult.fromMap(map);
  }

  @override
  Future<void> withdrawWallet({required double amount, String? walletId}) {
    return _remoteDataSource.withdrawWallet(amount: amount, walletId: walletId);
  }

  List<Map<String, dynamic>> _extractList(dynamic payload) {
    final data = payload is Map ? payload['data'] : payload;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }
}
