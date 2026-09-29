library;

import 'package:flutter/material.dart';

import '../../../../../core/config/app_config.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../shared/models/user_stats_view_data.dart';

class DriverProfileHeader extends StatelessWidget {
  const DriverProfileHeader({
    super.key,
    required this.name,
    required this.stats,
    this.photoUrl,
    this.onPhotoTap,
    this.isUploading = false,
    this.rangeLabel,
  });

  final String name;
  final UserStatsViewData stats;
  final String? photoUrl;
  final VoidCallback? onPhotoTap;
  final bool isUploading;
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    final avatarSize = context.responsiveValue<double>(
      compact: 72,
      phone: AppTheme.avatarLg,
      largePhone: AppTheme.avatarLg,
      tablet: 110,
    );
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _DriverAvatar(
              photoUrl: photoUrl,
              size: avatarSize,
              isUploading: isUploading,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: GestureDetector(
                onTap: onPhotoTap,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.greyLight),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.primaryDark,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(name, style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (rangeLabel != null) ...[
              _Tag(
                label: rangeLabel!,
                background: const Color(0xFFE7CE7A),
                color: const Color(0xFF4B3907),
              ),
              const SizedBox(width: 8),
            ],
            const _Tag(
              label: 'Actif',
              background: Color(0xFFD3F6DE),
              color: Color(0xFF0D7C2E),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_rounded, size: 20, color: AppColors.primaryDark),
            const SizedBox(width: 4),
            Text(stats.ratingLabel, style: AppTextStyles.h2),
            const SizedBox(width: 8),
            Text(
              '(${stats.ridesCountLabel} courses)',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({
    required this.size,
    this.photoUrl,
    this.isUploading = false,
  });

  final double size;
  final String? photoUrl;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveUrl(photoUrl);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: ClipOval(
            child: resolvedUrl == null
                ? Icon(Icons.person_outline_rounded, size: size * 0.44)
                : Image.network(
                    resolvedUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Icon(Icons.person_outline_rounded, size: size * 0.44),
                  ),
          ),
        ),
        if (isUploading)
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black26,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ),
      ],
    );
  }

  String? _resolveUrl(String? value) => Env.resolveProfilePhotoUrl(value);
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.background,
    required this.color,
  });

  final String label;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.buttonSmall.copyWith(color: color),
      ),
    );
  }
}
