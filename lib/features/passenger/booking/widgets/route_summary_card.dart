import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import 'package:fraya_mobile/shared/widgets/fraya_skeleton.dart';

class RouteSummaryCard extends StatelessWidget {
  const RouteSummaryCard({
    super.key,
    required this.originName,
    required this.destinationName,
    required this.distanceText,
    required this.durationText,
    this.onOriginTap,
    this.onDestinationTap,
  });

  final String originName;
  final String destinationName;
  final String distanceText;
  final String durationText;
  final VoidCallback? onOriginTap;
  final VoidCallback? onDestinationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        children: [
          // Indicateurs visuels origin/destination
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 2, height: 20, color: context.colors.greyLight),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Noms des lieux
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EditableAddressRow(
                  text: originName,
                  onTap: onOriginTap,
                  semanticsLabel: 'Modifier prise en charge',
                  isPrimary: true,
                ),
                const SizedBox(height: 8),
                _EditableAddressRow(
                  text: destinationName,
                  onTap: onDestinationTap,
                  semanticsLabel: 'Modifier destination',
                  isPrimary: false,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Distance et durée
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(distanceText, style: AppTextStyles.h4),
              const SizedBox(height: 4),
              Text(
                durationText,
                style: AppTextStyles.xs.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditableAddressRow extends StatelessWidget {
  const _EditableAddressRow({
    required this.text,
    required this.onTap,
    required this.semanticsLabel,
    required this.isPrimary,
  });

  final String text;
  final VoidCallback? onTap;
  final String semanticsLabel;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      style: isPrimary
          ? AppTextStyles.small.copyWith(fontWeight: FontWeight.w600)
          : AppTextStyles.small,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    if (onTap == null) return textWidget;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: textWidget),
            const SizedBox(width: 6),
            Tooltip(
              message: semanticsLabel,
              child: Icon(
                Icons.edit_location_alt_outlined,
                size: 14,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteSummarySkeleton extends StatelessWidget {
  const RouteSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.colors.border),
      ),
      child: const Row(
        children: [
          FrayaSkeleton(height: 48, width: 48, borderRadius: 12),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 150, height: 16),
                SizedBox(height: 8),
                SkeletonText(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
