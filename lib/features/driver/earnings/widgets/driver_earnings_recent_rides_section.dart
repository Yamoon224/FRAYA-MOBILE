library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../history/models/driver_history_day_section.dart';
import '../../history/widgets/driver_history_ride_card.dart';

class DriverEarningsRecentRidesSection extends StatelessWidget {
  const DriverEarningsRecentRidesSection({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h1.copyWith(fontSize: 16)),
        const SizedBox(height: AppTheme.spacingMd),
        if (sections.isEmpty)
          _EmptyState(message: emptyMessage)
        else
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
              child: _DaySection(section: section),
            ),
          ),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.section});

  final DriverHistoryDaySection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: Text(section.title, style: AppTextStyles.h4),
        ),
        ...section.rides.map(
          (ride) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            child: DriverHistoryRideCard(
              ride: ride,
              showCommissionBreakdown: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 32,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: 10),
          Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
