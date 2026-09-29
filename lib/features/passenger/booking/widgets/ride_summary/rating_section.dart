import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/extensions.dart';
import 'ride_rating_labels.dart';
import 'ride_star_rating_row.dart';

class RatingSection extends StatelessWidget {
  const RatingSection({
    super.key,
    required this.driverName,
    required this.driverRating,
    required this.currentRating,
    required this.currentComment,
    required this.onRatingChanged,
    required this.onCommentChanged,
  });

  final String driverName;
  final double driverRating;
  final int currentRating;
  final String currentComment;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<String> onCommentChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage('assets/images/gladiateur.png'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFC107),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(driverRating.toString(), style: AppTextStyles.small),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Text(
          'Comment etait votre course ?',
          style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        RideStarRatingRow(
          currentRating: currentRating,
          onRatingChanged: onRatingChanged,
          activeColor: AppColors.primary,
          inactiveColor: context.colors.greyLight,
          activeIcon: Icons.star,
          inactiveIcon: Icons.star_border,
          allowClear: false,
        ),
        if (currentRating > 0) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            rideRatingLabels[currentRating - 1],
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          TextFormField(
            initialValue: currentComment,
            onChanged: onCommentChanged,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Laissez un commentaire... (optionnel)',
              hintStyle: AppTextStyles.small.copyWith(
                color: context.colors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                borderSide: BorderSide(color: context.colors.greyLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                borderSide: BorderSide(color: context.colors.greyLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                borderSide: const BorderSide(color: AppColors.primaryDark),
              ),
              contentPadding: const EdgeInsets.all(AppTheme.spacingMd),
            ),
          ),
        ],
      ],
    );
  }
}
