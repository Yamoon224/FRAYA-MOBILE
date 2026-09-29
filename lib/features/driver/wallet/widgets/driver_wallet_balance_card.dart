library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive.dart';

class DriverWalletBalanceCard extends StatelessWidget {
  const DriverWalletBalanceCard({
    super.key,
    required this.balanceText,
    required this.onReloadPressed,
    required this.onSubscribePressed,
    this.walletId,
  });

  final String balanceText;
  final VoidCallback onReloadPressed;
  final VoidCallback onSubscribePressed;
  final String? walletId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.responsiveValue<double>(
          compact: 18,
          phone: 22,
          largePhone: 22,
          tablet: 26,
        ),
        context.responsiveValue<double>(
          compact: 18,
          phone: 20,
          largePhone: 20,
          tablet: 24,
        ),
        context.responsiveValue<double>(
          compact: 18,
          phone: 22,
          largePhone: 22,
          tablet: 26,
        ),
        context.responsiveValue<double>(
          compact: 16,
          phone: 18,
          largePhone: 18,
          tablet: 22,
        ),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1116), Color(0xFF2A2D33)],
        ),
        boxShadow: AppColors.shadowLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Solde de crédit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          if (walletId != null) ...[
            const SizedBox(height: 4),
            Text(
              'ID : $walletId',
              style: AppTextStyles.small.copyWith(
                color: Colors.white.withValues(alpha: 0.45),
                letterSpacing: 0.5,
              ),
            ),
          ],
          const SizedBox(height: 10),
          RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: balanceText,
              style: AppTextStyles.h1.copyWith(
                color: Colors.white,
                fontSize: context.responsiveValue<double>(
                  compact: 28,
                  phone: 42,
                  largePhone: 42,
                  tablet: 52,
                ),
                height: 1.1,
              ),
              children: [
                TextSpan(
                  text: ' FCFA',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: context.responsiveValue<double>(
                      compact: 20,
                      phone: 34,
                      largePhone: 34,
                      tablet: 42,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: _WalletActionButton(
                  label: 'Recharger',
                  icon: Icons.add_rounded,
                  onPressed: onReloadPressed,
                  filled: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WalletActionButton(
                  label: 'Souscription',
                  icon: Icons.card_membership_rounded,
                  onPressed: onSubscribePressed,
                  filled: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletActionButton extends StatelessWidget {
  const _WalletActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.filled,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: filled ? AppColors.goldGradient : null,
          border: filled
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.2,
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: filled ? AppColors.textPrimary : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.buttonSmall.copyWith(
                  color: filled ? AppColors.textPrimary : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
