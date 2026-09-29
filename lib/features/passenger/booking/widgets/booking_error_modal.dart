import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../../../../shared/widgets/fraya_dialog.dart';

class BookingErrorModal extends StatelessWidget {
  const BookingErrorModal({
    super.key,
    required this.message,
    required this.onModifyDestination,
    this.onRetry,
  });

  final String message;
  final VoidCallback onModifyDestination;
  final VoidCallback? onRetry;

  static Future<void> show(
    BuildContext context, {
    required String message,
    required VoidCallback onModifyDestination,
    VoidCallback? onRetry,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BookingErrorModal(
        message: message,
        onModifyDestination: onModifyDestination,
        onRetry: onRetry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = context.responsiveValue<double>(
      compact: 16,
      phone: 20,
      largePhone: 24,
      tablet: 32,
    );

    return FrayaDialog(
      padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FrayaDialogIcon(
            icon: Icons.error_outline_rounded,
            color: AppColors.error,
          ),
          const SizedBox(height: 20),
          Text(
            'Une erreur est survenue',
            textAlign: TextAlign.center,
            style: context.textH2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textSmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          FrayaButton(
            label: 'Modifier ma destination',
            leftIcon: Icons.edit_location_alt_outlined,
            onPressed: () {
              Navigator.of(context).pop();
              onModifyDestination();
            },
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            FrayaButton(
              label: 'Réessayer',
              leftIcon: Icons.refresh_rounded,
              variant: FrayaButtonVariant.outline,
              onPressed: () {
                Navigator.of(context).pop();
                onRetry!();
              },
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
