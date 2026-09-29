library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/constants.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/utils/measurement_formatter.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../data/sources/local_storage.dart';
import '../../../../../domain/models/driver_wallet_transaction.dart';
import '../../../../../shared/widgets/app_snack_bar.dart';
import '../providers/driver_wallet_provider.dart';
import '../widgets/driver_wallet_balance_card.dart';
import '../widgets/driver_wallet_commission_notice.dart';
import '../widgets/driver_wallet_operation_flow.dart';
import '../widgets/driver_wallet_transaction_tile.dart';

class DriverWalletScreen extends ConsumerStatefulWidget {
  const DriverWalletScreen({super.key});

  @override
  ConsumerState<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends ConsumerState<DriverWalletScreen> {
  static final NumberFormat _currency = NumberFormat('#,###', 'fr_FR');
  static final DateFormat _dateTimeFormat = DateFormat("d MMM, HH:mm", 'fr_FR');
  bool _isCommissionNoticeVisible = true;

  @override
  void initState() {
    super.initState();
    final storage = LocalStorage.instance;
    final isDismissed = storage.isInitialized
        ? storage.getBool(AppConstants.driverWalletCommissionNoticeDismissedKey)
        : false;
    _isCommissionNoticeVisible = isDismissed != true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(driverWalletProvider, (previous, next) {
      final error = next.errorMessage?.trim();
      if (error != null &&
          error.isNotEmpty &&
          error != previous?.errorMessage &&
          context.mounted) {
        AppSnackBar.showError(context, error);
      }
    });
    final state = ref.watch(driverWalletProvider);
    final backgroundColor = context.colors.background;
    final emptySurfaceColor = context.colors.surface;
    final emptyBorderColor = context.colors.greyLight;
    final emptyTextColor = context.colors.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _CircleIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Mon Portefeuille',
          style: AppTextStyles.h1.copyWith(fontSize: 20),
        ),
      ),
      body: state.isLoading && state.transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: context.responsiveBody(
                RefreshIndicator(
                  onRefresh: () async {
                    if (!ref.read(driverWalletProvider).isLoading) {
                      await ref
                          .read(driverWalletProvider.notifier)
                          .loadWallet();
                    }
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      context.horizontalPagePadding,
                      10,
                      context.horizontalPagePadding,
                      24,
                    ),
                    children: [
                      DriverWalletBalanceCard(
                        balanceText: _currency.format(state.balance),
                        walletId: state.walletId,
                        onReloadPressed: () =>
                            DriverWalletOperationFlow.showReloadFlow(
                              context: context,
                              ref: ref,
                            ),
                        onSubscribePressed: () =>
                            DriverWalletOperationFlow.showPackageFlow(
                              context: context,
                              ref: ref,
                            ),
                      ),
                      if (_isCommissionNoticeVisible) ...[
                        const SizedBox(height: AppTheme.spacingLg),
                        DriverWalletCommissionNotice(
                          onDismiss: _dismissCommissionNotice,
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingLg),
                      Text(
                        'Historique des transactions',
                        style: context.textH3.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      if (state.transactions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: emptySurfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: emptyBorderColor),
                          ),
                          child: Text(
                            'Aucune transaction disponible.',
                            style: AppTextStyles.body.copyWith(
                              color: emptyTextColor,
                            ),
                          ),
                        ),
                      ...state.transactions.map(
                        (tx) => DriverWalletTransactionTile(
                          transaction: tx,
                          amountText: _formatAmount(tx),
                          dateText: _dateTimeFormat.format(tx.occurredAt),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _formatAmount(DriverWalletTransaction tx) {
    final sign = tx.isCredit ? '+' : '-';
    return '$sign${MeasurementFormatter.formatCurrency(tx.amount)}';
  }

  Future<void> _dismissCommissionNotice() async {
    if (!_isCommissionNoticeVisible) return;
    setState(() => _isCommissionNoticeVisible = false);
    final storage = LocalStorage.instance;
    if (!storage.isInitialized) return;
    await storage.setBool(
      AppConstants.driverWalletCommissionNoticeDismissedKey,
      true,
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated,
        shape: BoxShape.circle,
        boxShadow: context.colors.isDark ? null : AppColors.shadowSm,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: context.colors.textPrimary,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
