import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/confirmation_action_column.dart';
import '../../../../shared/widgets/fraya_dialog.dart';

/// Confirmation avant de terminer la course là où se trouve le chauffeur
/// (le client descend avant la destination prévue).
Future<bool> showDriverEarlyStopConfirmationDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) =>
        _DriverEarlyStopConfirmationDialog(dialogContext: dialogContext),
  );
  return confirmed ?? false;
}

class _DriverEarlyStopConfirmationDialog extends StatelessWidget {
  const _DriverEarlyStopConfirmationDialog({required this.dialogContext});

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
            icon: Icons.flag_rounded,
            color: AppColors.warning,
          ),
          const SizedBox(height: 20),
          Text(
            'Terminer la course ici ?',
            textAlign: TextAlign.center,
            style: context.textH2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Le prix sera calculé sur le trajet parcouru.',
            textAlign: TextAlign.center,
            style: context.textSmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          ConfirmationActionColumn(
            primaryLabel: 'Oui, terminer ici',
            onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
            secondaryLabel: 'Continuer la course',
            onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
