library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../models/driver_ride_payment_method.dart';

class DriverRideCompletionPaymentSection extends StatelessWidget {
  const DriverRideCompletionPaymentSection({
    super.key,
    required this.selectedMethod,
    required this.onSelected,
    required this.enabled,
  });

  final DriverRidePaymentMethod selectedMethod;
  final ValueChanged<DriverRidePaymentMethod> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode de paiement',
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        for (final method in DriverRidePaymentMethod.values) ...[
          _PaymentTile(
            method: method,
            isSelected: selectedMethod == method,
            enabled: enabled,
            onTap: () => onSelected(method),
          ),
          if (method != DriverRidePaymentMethod.values.last)
            const SizedBox(height: AppTheme.spacingSm),
        ],
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.method,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final DriverRidePaymentMethod method;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFE9A6) : context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : context.colors.border,
          ),
          boxShadow: isSelected ? AppColors.shadowYellowSm : AppColors.shadowSm,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD4A843) : context.colors.greyExtraLight,
                shape: BoxShape.circle,
              ),
              child: Icon(method.icon, color: context.colors.textPrimary),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Text(
                method.label,
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD4A843) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFD4A843) : context.colors.border,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, size: 18, color: context.colors.textPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
