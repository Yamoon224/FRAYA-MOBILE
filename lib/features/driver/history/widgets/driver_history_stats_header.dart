library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/adaptive_split.dart';
import '../models/driver_history_stats.dart';

class DriverHistoryStatsHeader extends StatelessWidget {
  const DriverHistoryStatsHeader({
    super.key,
    required this.todayStats,
    required this.historyStats,
    this.historyLabel = 'Historique',
  });

  final DriverHistoryStats todayStats;
  final DriverHistoryStats historyStats;
  final String historyLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardPadding = EdgeInsets.all(
      context.responsiveValue<double>(
        compact: 18,
        phone: 22,
        largePhone: 24,
        tablet: 26,
      ),
    );

    return Container(
      padding: cardPadding,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? null : AppColors.shadowMd,
        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: AdaptiveSplit(
        breakpoint: 375,
        spacing: AppTheme.spacingMd,
        left: _StatColumn(
          label: "Aujourd'hui",
          primary: '${todayStats.completedRideCount} courses',
          secondary: todayStats.earnings.toCFA,
          tertiary: _ratingText(todayStats),
          isDark: isDark,
        ),
        right: _StatColumn(
          label: historyLabel,
          primary: '${historyStats.completedRideCount} courses',
          secondary: historyStats.earnings.toCFA,
          tertiary: _ratingText(historyStats),
          isDark: isDark,
        ),
      ),
    );
  }

  String _ratingText(DriverHistoryStats stats) {
    return stats.hasRating
        ? 'Note ${stats.ratingLabel} (${stats.ratedRideCount} avis)'
        : 'Note --';
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.isDark,
  });

  final String label;
  final String primary;
  final String secondary;
  final String tertiary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final innerBg = context.colors.background;
    final labelColor = context.colors.textSecondary;
    final primaryColor = context.colors.textPrimary;
    final tertiaryColor = context.colors.textTertiary;

    return Container(
      padding: EdgeInsets.all(
        context.responsiveValue<double>(
          compact: 16,
          phone: 18,
          largePhone: 18,
          tablet: 20,
        ),
      ),
      decoration: BoxDecoration(
        color: innerBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(color: labelColor),
          ),
          const SizedBox(height: 8),
          Text(
            primary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h4.copyWith(
              fontSize: context.responsiveValue<double>(
                compact: 16,
                phone: 18,
                largePhone: 18,
                tablet: 20,
              ),
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            secondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textBody.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: 4),
          Text(
            tertiary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.xs.copyWith(color: tertiaryColor),
          ),
        ],
      ),
    );
  }
}
