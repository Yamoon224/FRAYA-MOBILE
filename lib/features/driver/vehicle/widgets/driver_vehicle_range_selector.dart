library;

import 'package:flutter/material.dart';

import '../../../../core/models/ride_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';

class DriverVehicleRangeSelector extends StatelessWidget {
  const DriverVehicleRangeSelector({
    super.key,
    required this.selectedRange,
    required this.enabled,
    required this.onSelected,
  });

  final String selectedRange;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: RideCategory.defaultCategories.map((category) {
        final isSelected = category.id == selectedRange.toUpperCase();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: InkWell(
            onTap: enabled ? () => onSelected(category.id) : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colors.surfacePressed
                    : context.colors.greyExtraLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow:
                    isSelected ? AppColors.shadowYellowSm : AppColors.shadowSm,
              ),
              child: Row(
                children: [
                  Image.asset(
                    category.iconAsset,
                    width: 54,
                    height: 54,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name, style: AppTextStyles.h4),
                        const SizedBox(height: 2),
                        Text(category.description, style: AppTextStyles.small),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
