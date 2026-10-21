library;

import '../models/driver_wallet_overview.dart';
import '../models/driver_wallet_package.dart';
import '../models/driver_wallet_package_subscription_result.dart';
import '../models/driver_wallet_reload_result.dart';
import '../models/orange_money_payment.dart';

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

  Future<OrangeMoneyPayment> initializeOrangeMoneyReload({
    required double amount,
  });

  Future<OrangeMoneyPaymentStatus> verifyOrangeMoneyReload(String reference);

  Future<void> withdrawWallet({required double amount, String? walletId});
}
