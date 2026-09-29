import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/extensions.dart';
import '../../providers/sos_alert_controller.dart';
import 'sos_reason_sheet.dart';

class SosAlertSection extends ConsumerWidget {
  const SosAlertSection({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sosAlertControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.errorMessage != null) ...[
          Text(
            state.errorMessage!,
            style: AppTextStyles.small.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: state.isSubmitting
              ? null
              : () => SosReasonSheet.show(context, rideId),
          child: Text(
            state.isSubmitting ? 'Envoi en cours...' : 'Déclencher le SOS',
            style: AppTextStyles.body.copyWith(
              color: state.isSubmitting ? context.colors.textSecondary : AppColors.error,
              fontWeight: FontWeight.w600,
              decoration: state.isSubmitting ? null : TextDecoration.underline,
              decorationColor: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

}
