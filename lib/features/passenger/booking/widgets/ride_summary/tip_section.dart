import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/extensions.dart';

class TipSection extends StatelessWidget {
  const TipSection({
    super.key,
    required this.selectedTip,
    required this.onTipSelected,
  });

  final int? selectedTip;
  final ValueChanged<int?> onTipSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_border, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Ajouter un pourboire (optionnel)',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Montrez votre satisfaction au chauffeur',
          style: AppTextStyles.xs.copyWith(color: context.colors.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [500, 1000, 2000].map((amount) {
            final isSelected = selectedTip == amount;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onTipSelected(isSelected ? null : amount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : context.colors.greyExtraLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: Center(
                      child: Text(
                        amount.toCFA,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : context.colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
