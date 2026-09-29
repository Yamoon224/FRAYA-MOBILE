library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../models/driver_history_day_section.dart';
import 'driver_history_ride_card.dart';

class DriverHistoryListSection extends StatelessWidget {
  const DriverHistoryListSection({
    super.key,
    required this.title,
    required this.sections,
    required this.emptyMessage,
  });

  final String title;
  final List<DriverHistoryDaySection> sections;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = context.colors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h1.copyWith(fontSize: 20, color: titleColor),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (sections.isEmpty)
          _DriverHistoryEmptyState(message: emptyMessage, isDark: isDark)
        else
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
              child: _DriverHistoryDaySectionView(
                section: section,
                isDark: isDark,
              ),
            ),
          ),
      ],
    );
  }
}

class _DriverHistoryDaySectionView extends StatelessWidget {
  const _DriverHistoryDaySectionView({
    required this.section,
    required this.isDark,
  });

  final DriverHistoryDaySection section;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final sectionTitleColor = context.colors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: Text(
            section.title,
            style: AppTextStyles.h4.copyWith(color: sectionTitleColor),
          ),
        ),
        ...section.rides.map(
          (ride) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            child: DriverHistoryRideCard(ride: ride),
          ),
        ),
      ],
    );
  }
}

class _DriverHistoryEmptyState extends StatelessWidget {
  const _DriverHistoryEmptyState({
    required this.message,
    required this.isDark,
  });

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.colors.surface;
    final iconColor = context.colors.textSecondary;
    final textColor = context.colors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? null : AppColors.shadowMd,
        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 40,
            color: iconColor,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
