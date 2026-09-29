import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/ride_category.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import 'ride_category_card.dart';

class CategorySelectionSection extends ConsumerWidget {
  const CategorySelectionSection({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<RideCategory> categories;
  final RideCategory? selectedCategory;
  final Function(RideCategory) onCategorySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final driverCount = ref.watch(
    //   nearbyDriversProvider.select((d) => d.length),
    // );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez votre course',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        // Row(
        //   children: [
        //     const Icon(
        //       Icons.verified_outlined,
        //       color: AppColors.success,
        //       size: 16,
        //     ),
        //     const SizedBox(width: 4),
        //     Text(
        //       'Prix fixe garanti • Pas de surprises',
        //       style: AppTextStyles.xs.copyWith(color: AppColors.success),
        //     ),
        //   ],
        // ),
        // if (driverCount > 0) ...[
        //   const SizedBox(height: 4),
        //   Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Container(
        //         width: 8,
        //         height: 8,
        //         decoration: BoxDecoration(
        //           color: driverCount >= 3 ? AppColors.success : AppColors.warning,
        //           shape: BoxShape.circle,
        //         ),
        //       ),
        //       const SizedBox(width: 6),
        //       Text(
        //         driverCount == 1
        //             ? '1 chauffeur disponible'
        //             : '$driverCount chauffeurs disponibles',
        //         style: AppTextStyles.xs.copyWith(
        //           color: driverCount >= 3 ? AppColors.success : AppColors.warning,
        //           fontWeight: FontWeight.w500,
        //         ),
        //       ),
        //     ],
        //   ),
        // ],
        const SizedBox(height: AppTheme.spacingMd),
        ...categories.map(
          (category) => RideCategoryCard(
            category: category,
            isSelected: selectedCategory?.id == category.id,
            onTap: () => onCategorySelected(category),
          ),
        ),
      ],
    );
  }
}
