import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/models/user_stats_view_data.dart';
import '../models/profile_model.dart';

class ProfileStatsCard extends StatelessWidget {
  final PassengerProfile profile;

  const ProfileStatsCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final stats = UserStatsViewData(
      rating: profile.rating,
      ridesCount: profile.ridesCount,
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.greyExtraLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.star,
            iconColor: const Color(0xFFD4A843),
            value: stats.ratingLabel,
            label: 'Note',
          ),
          _StatItem(value: stats.ridesCountLabel, label: 'Courses'),
          _StatItem(
            value: profile.membershipDurationValue.toString(),
            label: profile.membershipDurationUnitLabel,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String value;
  final String label;

  const _StatItem({
    this.icon,
    this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.xs.copyWith(color: context.colors.textTertiary),
        ),
      ],
    );
  }
}
