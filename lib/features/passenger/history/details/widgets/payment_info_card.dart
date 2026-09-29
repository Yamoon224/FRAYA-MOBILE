import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/core/theme/app_colors.dart';
import 'package:fraya_mobile/core/theme/app_text_styles.dart';
import 'package:fraya_mobile/core/theme/app_theme.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import 'package:fraya_mobile/core/utils/responsive.dart';
import 'package:fraya_mobile/shared/widgets/adaptive_split.dart';

class PaymentInfoCard extends StatelessWidget {
  const PaymentInfoCard({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final amountText = '${NumberFormat("#,###").format(ride.price)} FCFA';

    return Container(
      padding: EdgeInsets.all(
        context.responsiveValue<double>(
          compact: AppTheme.spacingMd,
          phone: AppTheme.spacingLg,
          largePhone: AppTheme.spacingLg,
          tablet: 28,
        ),
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paiement',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          AdaptiveSplit(
            breakpoint: 375,
            spacing: 16,
            left: Text(
              'Methode de paiement',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            right: _PaymentMethodValue(method: ride.paymentMethod ?? 'Especes'),
          ),
          const SizedBox(height: 16),
          AdaptiveSplit(
            breakpoint: 375,
            spacing: 12,
            left: Text(
              'ID Transaction',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            right: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ride.transactionId ?? '---',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.xs.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: context.colors.greyExtraLight),
          const SizedBox(height: 16),
          AdaptiveSplit(
            breakpoint: 390,
            spacing: 12,
            left: Text(
              'Montant paye',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
            right: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                amountText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h2.copyWith(
                  color: const Color(0xFFD4A843),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodValue extends StatelessWidget {
  const _PaymentMethodValue({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.payment, size: 16, color: Color(0xFFD4A843)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            method,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
