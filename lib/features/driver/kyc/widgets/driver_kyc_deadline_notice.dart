library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

class DriverKycDeadlineNotice extends StatelessWidget {
  const DriverKycDeadlineNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.infoText.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.infoText),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              'Le casier judiciaire est optionnel maintenant, mais vous devrez le soumettre dans les 3 mois suivant votre inscription.',
              style: AppTextStyles.small.copyWith(color: AppColors.infoText),
            ),
          ),
        ],
      ),
    );
  }
}
