import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../models/profile_model.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    this.onPhotoTap,
    this.isUploading = false,
  });

  final PassengerProfile profile;
  final VoidCallback? onPhotoTap;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Row(
        children: [
          Stack(
            children: [
              _Avatar(photoUrl: profile.photoUrl, isUploading: isUploading),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: onPhotoTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.shadowSm,
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 18,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTheme.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.phone,
                  style: AppTextStyles.body.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                Text(
                  profile.email,
                  style: AppTextStyles.body.copyWith(
                    color: context.colors.textSecondary,
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, this.isUploading = false});

  final String? photoUrl;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolvePhotoUrl(photoUrl);
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: AppColors.shadowSm,
      ),
      child: ClipOval(
        child: isUploading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : resolvedUrl == null
                ? const Center(
                    child: Icon(
                      Icons.person_outline,
                      size: 50,
                      color: Colors.black87,
                    ),
                  )
                : Image.network(
                    resolvedUrl,
                    key: ValueKey(resolvedUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.person_outline,
                          size: 50,
                          color: Colors.black87,
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String? _resolvePhotoUrl(String? value) => Env.resolveProfilePhotoUrl(value);
}
