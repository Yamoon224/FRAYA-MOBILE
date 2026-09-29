import 'package:flutter/material.dart';
import 'package:fraya_mobile/core/utils/date_utils.dart';
import '../../../../core/models/ride_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import 'nearest_driver_eta_chip.dart';

class RideCategoryCard extends StatelessWidget {
  const RideCategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });
  final RideCategory category;
  final bool isSelected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final iconSize = compact ? 60.0 : 74.0;
          final rightColumnWidth = compact ? 92.0 : 108.0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: isSelected ? context.colors.surfacePressed : context.colors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: isSelected ? AppColors.primaryDark : context.colors.border,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? AppColors.shadowYellowSm
                  : AppColors.shadowSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Image.asset(category.iconAsset, fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CategoryInfo(category: category, compact: compact),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: rightColumnWidth,
                  child: _PriceAndBadge(
                    category: category,
                    isSelected: isSelected,
                    compact: compact,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryInfo extends StatelessWidget {
  const _CategoryInfo({required this.category, required this.compact});
  final RideCategory category;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _iconForCategory(category.id),
              size: compact ? 16 : 18,
              color: _colorForCategory(context, category.id),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          category.description,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            _MetaItem(icon: Icons.person_outline, text: '${category.seats}'),
            const NearestDriverEtaChip(),
          ],
        ),
      ],
    );
  }

  IconData _iconForCategory(String id) {
    switch (id) {
      case 'MAGIC':
        return Icons.auto_awesome;
      case 'GLADIATEUR':
        return Icons.shield_rounded;
      case 'ELITE':
        return Icons.diamond;
      default:
        return Icons.local_taxi;
    }
  }

  Color _colorForCategory(BuildContext context, String id) {
    switch (id) {
      case 'MAGIC':
        return const Color(0xFFFDB913);
      case 'GLADIATEUR':
        return const Color(0xFF6366F1);
      case 'ELITE':
        return const Color(0xFF3B82F6);
      default:
        return context.colors.textSecondary;
    }
  }
}

class _PriceAndBadge extends StatelessWidget {
  const _PriceAndBadge({
    required this.category,
    required this.isSelected,
    required this.compact,
  });
  final RideCategory category;
  final bool isSelected;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (category.badge != null)
          _CategoryBadge(
            text: category.badge!,
            categoryId: category.id,
            compact: compact,
          )
        else
          const SizedBox(height: 10),
        const SizedBox(height: 4),
        if (isSelected)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(Icons.check, size: 13, color: Colors.black),
          ),
        const SizedBox(height: 6),
        Text(
          AppDateUtils.formatPrice(category.price),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.h3.copyWith(
            color: isSelected ? AppColors.primaryDark : context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'FCFA',
          style: AppTextStyles.xs.copyWith(color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: context.colors.textTertiary),
        const SizedBox(width: 3),
        Text(text, style: AppTextStyles.small.copyWith(color: context.colors.textTertiary)),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.text,
    required this.categoryId,
    required this.compact,
  });
  final String text;
  final String categoryId;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final isSuccess = categoryId == 'MAGIC';
    final bgColor = isSuccess
        ? context.colors.successBackground
        : context.colors.infoBackground;
    final textColor = isSuccess ? AppColors.successText : AppColors.infoText;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: textColor.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.xs.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
