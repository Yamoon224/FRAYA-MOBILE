import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/confirmation_action_column.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../../../../shared/widgets/fraya_dialog.dart';

Future<bool> showDriverCancelRideConfirmationDialog(
  BuildContext context,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _DriverCancelRideConfirmationDialog(
      dialogContext: dialogContext,
    ),
  );
  return confirmed ?? false;
}

class _DriverCancelRideConfirmationDialog extends StatelessWidget {
  const _DriverCancelRideConfirmationDialog({required this.dialogContext});

  final BuildContext dialogContext;

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
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
          ),
          const SizedBox(height: 20),
          Text(
            'Annuler la course ?',
            textAlign: TextAlign.center,
            style: context.textH2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Voulez-vous vraiment annuler cette course ?',
            textAlign: TextAlign.center,
            style: context.textSmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          _WarningBanner(),
          const SizedBox(height: 24),
          ConfirmationActionColumn(
            primaryLabel: 'Oui, annuler',
            primaryVariant: FrayaButtonVariant.danger,
            onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
            secondaryLabel: 'Garder la course',
            onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Plus de 2 annulations peuvent entraîner une suspension temporaire de votre compte.',
              style: context.textSmall.copyWith(
                color: const Color(0xFF92400E),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
