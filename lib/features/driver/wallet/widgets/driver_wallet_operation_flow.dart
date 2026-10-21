library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../domain/models/driver_wallet_package.dart';
import '../../../../../domain/models/orange_money_payment.dart';
import '../models/driver_wallet_operation_result.dart';
import '../providers/driver_wallet_provider.dart';
import '../screens/driver_orange_money_payment_screen.dart';
import 'driver_wallet_operation_progress_sheet.dart';
import 'driver_wallet_operation_result_sheet.dart';
import 'driver_wallet_package_sheet.dart';
import 'driver_wallet_payment_sheet.dart';

class DriverWalletOperationFlow {
  static final NumberFormat _currency = NumberFormat('#,###', 'fr_FR');

  static Future<void> showReloadFlow({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    DriverWalletReloadDraft? draft = await _showReloadForm(context);
    while (draft != null && context.mounted) {
      if (!context.mounted) return;
      final reloadDraft = draft;
      final DriverWalletOperationResult result;
      if (reloadDraft.paymentMethod == _orangeMoneyMethod) {
        result = await _runOrangeMoneyReload(
          context: context,
          ref: ref,
          amount: reloadDraft.amount,
        );
      } else {
        result = await _runWithProgress(
          context: context,
          operationType: DriverWalletOperationType.reload,
          action: () => ref
              .read(driverWalletProvider.notifier)
              .reloadWallet(
                amount: reloadDraft.amount,
                walletId: ref.read(driverWalletProvider).walletId,
              ),
        );
      }
      if (!context.mounted || result.isIgnored) return;
      final action = await _showResult(context, result);
      if (result.isSuccess || action == DriverWalletResultAction.close) return;
      if (action == DriverWalletResultAction.retry) continue;
      if (!context.mounted) return;
      draft = await _showReloadForm(context, initialDraft: draft);
    }
  }

  static const String _orangeMoneyMethod = 'orange_money';

  /// Orange Money : création du paiement, règlement dans la page Orange, puis vérification serveur.
  static Future<DriverWalletOperationResult> _runOrangeMoneyReload({
    required BuildContext context,
    required WidgetRef ref,
    required double amount,
  }) async {
    final notifier = ref.read(driverWalletProvider.notifier);
    final started = await _runWithProgress(
      context: context,
      operationType: DriverWalletOperationType.reload,
      action: () => notifier.startOrangeMoneyReload(amount: amount),
    );
    final payment = started.payload;
    if (!started.isSuccess || payment is! OrangeMoneyPayment) return started;
    if (!context.mounted) {
      return DriverWalletOperationResult.ignored(
        DriverWalletOperationType.reload,
      );
    }

    final outcome = await Navigator.of(context).push<OrangeMoneyPaymentStatus>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DriverOrangeMoneyPaymentScreen(
          payment: payment,
          check: () => notifier.checkOrangeMoneyReload(payment.reference),
        ),
      ),
    );
    if (!context.mounted) {
      return DriverWalletOperationResult.ignored(
        DriverWalletOperationType.reload,
      );
    }
    return _runWithProgress(
      context: context,
      operationType: DriverWalletOperationType.reload,
      action: () =>
          notifier.finishOrangeMoneyReload(payment: payment, outcome: outcome),
    );
  }

  static Future<void> showPackageFlow({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    var package = await _showPackageSheet(context, ref);
    if (package == null || !context.mounted) return;
    while (package != null && context.mounted) {
      final selectedPackage = package;
      if (!context.mounted) return;
      final result = await _runWithProgress(
        context: context,
        operationType: DriverWalletOperationType.packageSubscription,
        action: () => ref
            .read(driverWalletProvider.notifier)
            .subscribeToPackage(selectedPackage),
      );
      if (!context.mounted || result.isIgnored) return;
      final action = await _showResult(context, result);
      if (result.isSuccess || action == DriverWalletResultAction.close) return;
      if (action == DriverWalletResultAction.retry) continue;
      if (!context.mounted) return;
      package = await _showPackageSheet(
        context,
        ref,
        initialSelectedPackage: selectedPackage,
      );
    }
  }

  static Future<DriverWalletReloadDraft?> _showReloadForm(
    BuildContext context, {
    DriverWalletReloadDraft? initialDraft,
  }) {
    return showModalBottomSheet<DriverWalletReloadDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DriverWalletPaymentSheet(
          title: 'Recharger le compte',
          confirmLabel: 'Confirmer le paiement',
          initialAmount: initialDraft?.amount,
          initialMethod: initialDraft?.paymentMethod,
          onSubmit: (draft) async => Navigator.of(context).pop(draft),
        ),
      ),
    );
  }

  static Future<DriverWalletPackage?> _showPackageSheet(
    BuildContext context,
    WidgetRef ref, {
    DriverWalletPackage? initialSelectedPackage,
  }) async {
    final notifier = ref.read(driverWalletProvider.notifier);
    unawaited(notifier.loadPackages());
    return showModalBottomSheet<DriverWalletPackage>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
      ),
      builder: (_) => Consumer(
        builder: (sheetContext, ref, _) {
          final walletState = ref.watch(driverWalletProvider);
          return DriverWalletPackageSheet(
            packages: walletState.packages,
            isLoading: walletState.isLoadingPackages,
            walletBalanceText: _currency.format(walletState.balance),
            initialSelectedPackage: initialSelectedPackage,
            onRefresh: () => unawaited(
              ref
                  .read(driverWalletProvider.notifier)
                  .loadPackages(forceRefresh: true),
            ),
            onConfirmPackage: (package) async =>
                Navigator.of(sheetContext).pop(package),
          );
        },
      ),
    );
  }

  static Future<DriverWalletOperationResult> _runWithProgress({
    required BuildContext context,
    required DriverWalletOperationType operationType,
    required Future<DriverWalletOperationResult> Function() action,
  }) async {
    BuildContext? progressContext;
    final progressFuture = showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
      ),
      builder: (sheetContext) {
        progressContext = sheetContext;
        return DriverWalletOperationProgressSheet(operationType: operationType);
      },
    );
    await WidgetsBinding.instance.endOfFrame;
    final result = await action();
    if (progressContext != null && progressContext!.mounted) {
      Navigator.of(progressContext!).pop();
    }
    await progressFuture;
    return result;
  }

  static Future<DriverWalletResultAction> _showResult(
    BuildContext context,
    DriverWalletOperationResult result,
  ) async {
    final action = await showModalBottomSheet<DriverWalletResultAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
      ),
      builder: (_) => DriverWalletOperationResultSheet(result: result),
    );
    return action ?? DriverWalletResultAction.close;
  }
}
