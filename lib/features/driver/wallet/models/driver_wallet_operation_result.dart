library;

import '../../../../../domain/models/driver_wallet_package_subscription_result.dart';
import '../../../../../domain/models/driver_wallet_reload_result.dart';

enum DriverWalletOperationType { reload, packageSubscription }

enum DriverWalletResultAction { close, retry, edit }

class DriverWalletReloadDraft {
  const DriverWalletReloadDraft({
    required this.amount,
    required this.paymentMethod,
  });

  final double amount;
  final String paymentMethod;
}

class DriverWalletOperationResult {
  const DriverWalletOperationResult({
    required this.operationType,
    required this.isSuccess,
    required this.isIgnored,
    required this.message,
    this.payload,
  });

  final DriverWalletOperationType operationType;
  final bool isSuccess;
  final bool isIgnored;
  final String message;
  final Object? payload;

  factory DriverWalletOperationResult.reloadSuccess(
    DriverWalletReloadResult response,
  ) {
    return DriverWalletOperationResult(
      operationType: DriverWalletOperationType.reload,
      isSuccess: true,
      isIgnored: false,
      message: response.message,
      payload: response,
    );
  }

  factory DriverWalletOperationResult.packageSuccess(
    DriverWalletPackageSubscriptionResult response,
  ) {
    return DriverWalletOperationResult(
      operationType: DriverWalletOperationType.packageSubscription,
      isSuccess: true,
      isIgnored: false,
      message: response.message,
      payload: response,
    );
  }

  factory DriverWalletOperationResult.failure({
    required DriverWalletOperationType operationType,
    required String message,
  }) {
    return DriverWalletOperationResult(
      operationType: operationType,
      isSuccess: false,
      isIgnored: false,
      message: message,
    );
  }

  factory DriverWalletOperationResult.ignored(
    DriverWalletOperationType operationType,
  ) {
    return DriverWalletOperationResult(
      operationType: operationType,
      isSuccess: false,
      isIgnored: true,
      message: '',
    );
  }
}
