library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';

class DriverWalletCommissionNotice extends StatelessWidget {
  const DriverWalletCommissionNotice({required this.onDismiss, super.key});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = context.colors.isDark
        ? const Color(0xFF302710)
        : const Color(0xFFFFF8E1);
    final borderColor = context.colors.isDark
        ? AppColors.primaryDark.withValues(alpha: 0.55)
        : const Color(0xFFF3D27A);
    final titleColor = context.colors.textPrimary;
    final bodyColor = context.colors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDB3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF9A6700),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Information importante',
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 15,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sans souscription au package illimité, les commissions Fraya de vos courses seront retirées de votre portefeuille.',
                  style: AppTextStyles.small.copyWith(
                    color: bodyColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Masquer cette information',
            visualDensity: VisualDensity.compact,
            splashRadius: 18,
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: bodyColor,
          ),
        ],
      ),
    );
  }
}
