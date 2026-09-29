library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import 'fraya_button.dart';

class ConfirmationActionColumn extends StatelessWidget {
  const ConfirmationActionColumn({
    super.key,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.primaryVariant = FrayaButtonVariant.primary,
    this.isSubmitting = false,
  });

  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final FrayaButtonVariant primaryVariant;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final isDanger = primaryVariant == FrayaButtonVariant.danger;
    final secondaryLabel = this.secondaryLabel;
    final onSecondaryPressed = this.onSecondaryPressed;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isDanger ? AppColors.error : AppColors.primary,
              foregroundColor: isDanger ? Colors.white : context.colors.textPrimary,
              textStyle: AppTextStyles.button,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
            ),
            onPressed: isSubmitting ? null : onPrimaryPressed,
            child: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(primaryLabel, textAlign: TextAlign.center),
          ),
        ),
        if (secondaryLabel != null && onSecondaryPressed != null) ...[
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.textPrimary,
                textStyle: AppTextStyles.button,
                side: BorderSide(color: context.colors.greyLight, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
              onPressed: isSubmitting ? null : onSecondaryPressed,
              child: Text(secondaryLabel, textAlign: TextAlign.center),
            ),
          ),
        ],
      ],
    );
  }
}
