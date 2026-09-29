import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

class TollMention extends StatelessWidget {
  const TollMention({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "Les frais de péage sont à la charge du client si l'itinéraire emprunte un passage à péage.",
              style: AppTextStyles.xs.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
