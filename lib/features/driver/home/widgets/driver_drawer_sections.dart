library;

import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/models/user_stats_view_data.dart';

class DriverIdentityHeader extends StatelessWidget {
  const DriverIdentityHeader({
    super.key,
    required this.fullName,
    required this.stats,
    this.photoUrl,
    this.rangeLabel,
  });

  final String fullName;
  final UserStatsViewData stats;
  final String? photoUrl;
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    final titleColor = context.colors.textPrimary;
    final subtitleColor = context.colors.textSecondary;

    final avatarSize = context.responsiveValue<double>(
      compact: 54,
      phone: 62,
      largePhone: 62,
      tablet: 72,
    );
    final resolvedUrl = _resolveUrl(photoUrl);
    return Row(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: ClipOval(
            child: resolvedUrl == null
                ? Icon(Icons.person_outline_rounded, size: avatarSize * 0.48)
                : Image.network(
                    resolvedUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.person_outline_rounded,
                      size: avatarSize * 0.48,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName,
                style: AppTextStyles.h2.copyWith(
                  color: titleColor,
                  fontSize: 20,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                rangeLabel == null ? 'Chauffeur' : 'Chauffeur $rangeLabel',
                style: AppTextStyles.small.copyWith(color: subtitleColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.primaryDark,
                    size: 16,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      '${stats.ratingLabel} (${stats.ridesCountLabel} courses)',
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _resolveUrl(String? value) => Env.resolveProfilePhotoUrl(value);
}

class DriverDrawerItem extends StatelessWidget {
  const DriverDrawerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = context.colors.textPrimary;
    final hoverColor = context.colors.isDark
        ? context.colors.surfaceElevated
        : AppColors.primaryLight.withValues(alpha: 0.15);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      hoverColor: hoverColor,
      splashColor: AppColors.primaryDark.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryDark, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.h3.copyWith(color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverDrawerToggleItem extends StatelessWidget {
  const DriverDrawerToggleItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textColor = context.colors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.h3.copyWith(color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryDark,
          ),
        ],
      ),
    );
  }
}

class DriverHelpCard extends StatelessWidget {
  const DriverHelpCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.colors.surfaceElevated;
    final borderColor = context.colors.greyLight;
    final titleColor = context.colors.textPrimary;
    final subtitleColor = context.colors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Besoin d'aide ?",
            style: AppTextStyles.h1.copyWith(color: titleColor),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onPressed,
            child: Row(
              children: [
                Icon(Icons.phone_outlined, color: subtitleColor, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Support chauffeur',
                    style: AppTextStyles.small.copyWith(color: subtitleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onPressed,
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: subtitleColor,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chat en direct',
                    style: AppTextStyles.small.copyWith(color: subtitleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
