import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../shared/widgets/confirmation_action_column.dart';
import '../../../../../shared/widgets/fraya_button.dart';
import '../../../../../shared/widgets/fraya_dialog.dart';
import '../../providers/booking_provider.dart';

class CancelRideDialog {
  static void show(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _CancelRideDialog(
        dialogContext: dialogContext,
        ref: ref,
      ),
    );
  }
}

class _CancelRideDialog extends StatelessWidget {
  const _CancelRideDialog({
    required this.dialogContext,
    required this.ref,
  });

  final BuildContext dialogContext;
  final WidgetRef ref;

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
            'Des frais d\'annulation peuvent s\'appliquer selon les conditions tarifaires.',
            textAlign: TextAlign.center,
            style: context.textSmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          ConfirmationActionColumn(
            primaryLabel: 'Annuler la course',
            primaryVariant: FrayaButtonVariant.danger,
            onPrimaryPressed: () {
              ref.read(bookingFlowProvider.notifier).reset();
              Navigator.pop(dialogContext);
            },
            secondaryLabel: 'Garder la course',
            onSecondaryPressed: () => Navigator.pop(dialogContext),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
