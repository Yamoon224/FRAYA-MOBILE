import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/models/user_stats_view_data.dart';

class PassengerDrawerUserInfo extends StatelessWidget {
  const PassengerDrawerUserInfo({
    super.key,
    required this.userData,
    required this.stats,
    this.profilePhotoUrl,
  });

  final Map<String, dynamic>? userData;
  final UserStatsViewData stats;
  final String? profilePhotoUrl;

  @override
  Widget build(BuildContext context) {
    final textColor = context.colors.textPrimary;
    final secondaryTextColor = context.colors.textSecondary;
    final name =
        userData?['firstName'] ?? userData?['firstNames'] ?? 'Utilisateur';
    final phone = userData?['phoneNumber'] ?? userData?['phone'] ?? '';
    final photoUrl =
        profilePhotoUrl ??
        userData?['profilePhoto'] ??
        userData?['photo'] ??
        userData?['avatar'];

    return Row(
      children: [
        _PassengerAvatar(photoUrl: photoUrl?.toString()),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.h2.copyWith(color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (phone.isNotEmpty)
                Text(
                  phone,
                  style: AppTextStyles.small.copyWith(
                    color: secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.primaryDark,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      stats.ratingLabel,
                      style: AppTextStyles.small.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
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
}

class _PassengerAvatar extends StatelessWidget {
  const _PassengerAvatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = Env.resolveProfilePhotoUrl(photoUrl);
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: ClipOval(
        child: resolvedUrl == null
            ? const Center(
                child: Icon(
                  Icons.person_outline,
                  size: 32,
                  color: Colors.black87,
                ),
              )
            : Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(
                    Icons.person_outline,
                    size: 32,
                    color: Colors.black87,
                  ),
                ),
              ),
      ),
    );
  }
}

class PassengerDrawerToggleItem extends StatelessWidget {
  const PassengerDrawerToggleItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
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
              title,
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

class PassengerDrawerMenuItem extends StatelessWidget {
  const PassengerDrawerMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = context.colors.textPrimary;

    final hoverColor = context.colors.isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.primaryLight.withValues(alpha: 0.15);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                title,
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
