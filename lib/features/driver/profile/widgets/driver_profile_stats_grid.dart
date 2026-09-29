library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/utils/responsive.dart';

class DriverProfileStatsGrid extends StatelessWidget {
  const DriverProfileStatsGrid({
    super.key,
    required this.totalRidesLabel,
    required this.ratingLabel,
  });

  final String totalRidesLabel;
  final String ratingLabel;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.directions_car_outlined,
              value: totalRidesLabel,
              label: 'Courses totales',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.star_border_rounded,
              value: ratingLabel,
              label: 'Note moyenne',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.colors.surfaceElevated;
    final valueColor = context.colors.textPrimary;
    final labelColor = context.colors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 24),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.h1.copyWith(
              color: valueColor,
              fontSize: context.responsiveValue<double>(
                compact: 24,
                phone: 30,
                largePhone: 30,
                tablet: 36,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.small.copyWith(color: labelColor)),
        ],
      ),
    );
  }
}
