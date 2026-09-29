import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/confirmation_action_column.dart';
import '../../../../shared/widgets/fraya_dialog.dart';

Future<bool> showDriverArrivalConfirmationDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _DriverArrivalConfirmationDialog(
      dialogContext: dialogContext,
    ),
  );
  return confirmed ?? false;
}

class _DriverArrivalConfirmationDialog extends StatelessWidget {
  const _DriverArrivalConfirmationDialog({required this.dialogContext});

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
            icon: Icons.place_outlined,
            color: AppColors.success,
          ),
          const SizedBox(height: 20),
          Text(
            'Êtes-vous arrivé à destination ?',
            textAlign: TextAlign.center,
            style: context.textH2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Votre position indique que vous êtes proche de la destination du passager.',
            textAlign: TextAlign.center,
            style: context.textSmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          ConfirmationActionColumn(
            primaryLabel: 'Oui, je suis arrivé',
            onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
            secondaryLabel: 'Pas encore arrivé',
            onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
