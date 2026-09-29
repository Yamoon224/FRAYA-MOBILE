library;

import '../../../../../domain/models/driver_wallet_transaction.dart';
import '../../../../../domain/models/driver_wallet_package.dart';

class DriverWalletState {
  const DriverWalletState({
    this.isLoading = false,
    this.isLoadingPackages = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.balance = 0,
    this.walletId,
    this.packages = const <DriverWalletPackage>[],
    this.transactions = const <DriverWalletTransaction>[],
  });

  final bool isLoading;
  final bool isLoadingPackages;
  final bool isSubmitting;
  final String? errorMessage;
  final double balance;
  final String? walletId;
  final List<DriverWalletPackage> packages;
  final List<DriverWalletTransaction> transactions;

  DriverWalletState copyWith({
    bool? isLoading,
    bool? isLoadingPackages,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    double? balance,
    Object? walletId = _sentinel,
    List<DriverWalletPackage>? packages,
    List<DriverWalletTransaction>? transactions,
  }) {
    return DriverWalletState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingPackages: isLoadingPackages ?? this.isLoadingPackages,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      balance: balance ?? this.balance,
      walletId: identical(walletId, _sentinel)
          ? this.walletId
          : walletId as String?,
      packages: packages ?? this.packages,
      transactions: transactions ?? this.transactions,
    );
  }
}

const Object _sentinel = Object();
