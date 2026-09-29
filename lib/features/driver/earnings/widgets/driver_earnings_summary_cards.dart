library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/measurement_formatter.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/adaptive_split.dart';
import '../models/driver_earnings_summary.dart';

class DriverEarningsSummaryCards extends StatelessWidget {
  const DriverEarningsSummaryCards({super.key, required this.summary});

  final DriverEarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardPadding = EdgeInsets.all(
      context.responsiveValue<double>(
        compact: 18,
        phone: 22,
        largePhone: 24,
        tablet: 28,
      ),
    );

    return Column(
      children: [
        Container(
          padding: cardPadding,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(
              context.responsiveValue<double>(
                compact: 22,
                phone: 26,
                largePhone: 28,
                tablet: 30,
              ),
            ),
            boxShadow: AppColors.shadowYellowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.attach_money_rounded,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recettes de la période',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textBody.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.totalEarnings.toCFA,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h1.copyWith(
                  fontSize: context.responsiveValue<double>(
                    compact: 22,
                    phone: 28,
                    largePhone: 28,
                    tablet: 34,
                  ),
                  height: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              if (summary.totalCommission > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Net après commissions : ${summary.totalNetEarnings.toCFA}',
                  style: context.textSmall.copyWith(
                    color: const Color(0xFF2C2C2C),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingMd),
              _SummaryMetrics(summary: summary, isDark: isDark),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        AdaptiveSplit(
          breakpoint: 375,
          spacing: AppTheme.spacingMd,
          left: _MiniStatCard(
            title: 'Panier moyen',
            value: summary.averagePerRide.toCFA,
            icon: Icons.trending_up_rounded,
            accentColor: const Color(0xFF16A34A),
            accentBackground: isDark
                ? AppColors.darkSuccessBackground
                : const Color(0xFFE8FAEE),
            isDark: isDark,
          ),
          right: _MiniStatCard(
            title: 'Gain / heure de course',
            value: MeasurementFormatter.formatCurrencyPerHour(
              summary.earningsPerTripHour,
            ),
            icon: Icons.access_time_filled_rounded,
            accentColor: const Color(0xFF2563EB),
            accentBackground: isDark
                ? AppColors.darkInfoBackground
                : const Color(0xFFEAF1FF),
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _SummaryMetrics extends StatelessWidget {
  const _SummaryMetrics({required this.summary, required this.isDark});

  final DriverEarningsSummary summary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricItem(
        label: 'Courses',
        value: '${summary.completedRideCount}',
        isDark: isDark,
      ),
      _MetricItem(
        label: 'Temps en course',
        value: _formatTripTime(summary.totalTripMinutes),
        isDark: isDark,
      ),
      _MetricItem(
        label: 'Commission Fraya',
        value: summary.totalCommission.toCFA,
        isDark: isDark,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final dividerColor = isDark
            ? AppColors.darkBorder
            : const Color(0xFFD6D8DC);

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveValue<double>(
              compact: 14,
              phone: 16,
              largePhone: 18,
              tablet: 20,
            ),
            vertical: context.responsiveValue<double>(
              compact: 12,
              phone: 14,
              largePhone: 16,
              tablet: 18,
            ),
          ),
          decoration: BoxDecoration(
            color: context.colors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
          ),
          child: isCompact
              ? Column(
                  children: [
                    for (var index = 0; index < metrics.length; index++) ...[
                      metrics[index],
                      if (index < metrics.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: dividerColor),
                        ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: metrics[0]),
                    _MetricDivider(isDark: isDark),
                    Expanded(child: metrics[1]),
                    _MetricDivider(isDark: isDark),
                    Expanded(child: metrics[2]),
                  ],
                ),
        );
      },
    );
  }

  String _formatTripTime(int totalTripMinutes) {
    if (totalTripMinutes <= 0) return '0h';
    return '${totalTripMinutes ~/ 60}h ${totalTripMinutes % 60}min';
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.xs.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.h4.copyWith(
            fontSize: context.responsiveValue<double>(
              compact: 15,
              phone: 16,
              largePhone: 16,
              tablet: 18,
            ),
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 1,
      color: context.colors.border,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.accentBackground,
    required this.isDark,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color accentBackground;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.colors.surface;
    final titleColor = context.colors.textSecondary;

    return Container(
      constraints: BoxConstraints(
        minHeight: context.responsiveValue<double>(
          compact: 136,
          phone: 144,
          largePhone: 148,
          tablet: 156,
        ),
      ),
      padding: EdgeInsets.all(
        context.responsiveValue<double>(
          compact: 16,
          phone: 18,
          largePhone: 18,
          tablet: 20,
        ),
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark ? null : AppColors.shadowMd,
        border: isDark
            ? Border.all(color: AppColors.darkBorder)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: accentBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(color: titleColor),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h4.copyWith(
              fontSize: context.responsiveValue<double>(
                compact: 16,
                phone: 18,
                largePhone: 18,
                tablet: 20,
              ),
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
