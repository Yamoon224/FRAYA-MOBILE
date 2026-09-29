library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/fraya_button.dart';
import '../models/driver_wallet_operation_result.dart';

class DriverWalletOperationResultSheet extends StatelessWidget {
  const DriverWalletOperationResultSheet({super.key, required this.result});

  final DriverWalletOperationResult result;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: result.isSuccess
                    ? AppColors.successBackground
                    : const Color(0xFFFCEDEE),
              ),
              child: Icon(
                result.isSuccess
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                size: 38,
                color: result.isSuccess
                    ? AppColors.successText
                    : AppColors.error,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            if (result.isSuccess)
              FrayaButton(
                label: 'Fermer',
                onPressed: () =>
                    Navigator.of(context).pop(DriverWalletResultAction.close),
              )
            else ...[
              FrayaButton(
                label: 'Réessayer',
                onPressed: () =>
                    Navigator.of(context).pop(DriverWalletResultAction.retry),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              FrayaButton(
                label: 'Modifier',
                variant: FrayaButtonVariant.outline,
                onPressed: () =>
                    Navigator.of(context).pop(DriverWalletResultAction.edit),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
