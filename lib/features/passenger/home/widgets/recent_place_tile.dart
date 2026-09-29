import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';

class RecentPlaceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const RecentPlaceTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleColor = context.colors.textSecondary;
    final iconColor = context.colors.greyLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(Icons.business, color: Colors.black, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h4),
                  Text(
                    subtitle,
                    style: AppTextStyles.xs.copyWith(color: subtitleColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.access_time, color: iconColor, size: 18),
          ],
        ),
      ),
    );
  }
}
