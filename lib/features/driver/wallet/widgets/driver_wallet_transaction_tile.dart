library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../domain/models/driver_wallet_transaction.dart';

class DriverWalletTransactionTile extends StatelessWidget {
  const DriverWalletTransactionTile({
    super.key,
    required this.transaction,
    required this.amountText,
    required this.dateText,
  });

  final DriverWalletTransaction transaction;
  final String amountText;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    final visual = _visualSpec(transaction.type, transaction.isCredit);
    final surfaceColor = context.colors.surface;
    final borderColor = context.colors.greyLight;
    final titleColor = context.colors.textPrimary;
    final subtitleColor = context.colors.textSecondary;
    final amountColor = visual.amountColor == AppColors.textPrimary
        ? context.colors.textPrimary
        : visual.amountColor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: context.colors.isDark ? null : AppColors.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: visual.iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(visual.icon, color: visual.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: AppTextStyles.h2.copyWith(color: titleColor),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateText • ${transaction.source ?? 'Fraya'}',
                  style: AppTextStyles.small.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: AppTextStyles.h2.copyWith(color: amountColor),
          ),
        ],
      ),
    );
  }

  _WalletTransactionVisual _visualSpec(
    DriverWalletTransactionType type,
    bool isCredit,
  ) {
    if (isCredit) {
      return const _WalletTransactionVisual(
        icon: Icons.account_balance_wallet_outlined,
        iconColor: Color(0xFF16A34A),
        iconBackground: Color(0xFFE8F7EE),
        amountColor: Color(0xFF00A82D),
      );
    }
    switch (type) {
      case DriverWalletTransactionType.packagePurchase:
        return const _WalletTransactionVisual(
          icon: Icons.card_membership_rounded,
          iconColor: Color(0xFF9A6700),
          iconBackground: Color(0xFFFFF4D6),
          amountColor: Color(0xFF9A6700),
        );
      case DriverWalletTransactionType.commission:
        return const _WalletTransactionVisual(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: Color(0xFFDC2626),
          iconBackground: Color(0xFFFCEDEE),
          amountColor: AppColors.textPrimary,
        );
      case DriverWalletTransactionType.withdrawal:
      case DriverWalletTransactionType.other:
        return const _WalletTransactionVisual(
          icon: Icons.remove_circle_outline_rounded,
          iconColor: Color(0xFFB45309),
          iconBackground: Color(0xFFFFF3E0),
          amountColor: AppColors.textPrimary,
        );
      case DriverWalletTransactionType.recharge:
        return const _WalletTransactionVisual(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: Color(0xFF16A34A),
          iconBackground: Color(0xFFE8F7EE),
          amountColor: Color(0xFF00A82D),
        );
    }
  }
}

class _WalletTransactionVisual {
  const _WalletTransactionVisual({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.amountColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color amountColor;
}
