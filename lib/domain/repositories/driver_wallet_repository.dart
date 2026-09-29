library;

import '../models/driver_wallet_overview.dart';
import '../models/driver_wallet_package.dart';
import '../models/driver_wallet_package_subscription_result.dart';
import '../models/driver_wallet_reload_result.dart';

abstract class DriverWalletRepository {
  Future<DriverWalletOverview> fetchWalletOverview();

  Future<List<DriverWalletPackage>> fetchPackages();

  Future<DriverWalletPackageSubscriptionResult> subscribeToPackage({
    required int sidUserId,
    required int packageId,
  });

  Future<DriverWalletReloadResult> reloadWallet({
    required double amount,
    String? walletId,
  });

  Future<void> withdrawWallet({required double amount, String? walletId});
}
