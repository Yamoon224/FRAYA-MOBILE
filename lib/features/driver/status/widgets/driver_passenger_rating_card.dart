library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import 'driver_passenger_rating_labels.dart';

class DriverPassengerRatingCard extends StatelessWidget {
  const DriverPassengerRatingCard({
    super.key,
    required this.passengerName,
    required this.rating,
    required this.comment,
    required this.onRatingChanged,
    required this.onCommentChanged,
    required this.enabled,
  });

  final String passengerName;
  final int rating;
  final String comment;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<String> onCommentChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: context.colors.greyExtraLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passengerName,
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Comment s est passee la course ?',
                      style: AppTextStyles.small.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(5, (index) {
              final star = index + 1;
              final isActive = rating >= star;
              return IconButton(
                onPressed: enabled ? () => onRatingChanged(star) : null,
                icon: Icon(
                  isActive ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 34,
                  color: isActive
                      ? AppColors.primaryDark
                      : context.colors.textTertiary,
                ),
              );
            }),
          ),
          if (rating > 0) ...[
            Center(
              child: Text(
                driverPassengerRatingLabels[rating - 1],
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Touchez la meme etoile pour annuler la note',
                style: AppTextStyles.small.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingMd),
          TextFormField(
            enabled: enabled,
            initialValue: comment,
            minLines: 4,
            maxLines: 4,
            onChanged: onCommentChanged,
            decoration: InputDecoration(
              hintText: 'Commentaire (optionnel)',
              hintStyle: AppTextStyles.body.copyWith(
                color: context.colors.textTertiary,
              ),
              filled: true,
              fillColor: context.colors.surface,
              contentPadding: const EdgeInsets.all(AppTheme.spacingMd),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: context.colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: context.colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.primaryDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
