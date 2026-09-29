import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/fraya_button.dart';
import '../../providers/ride_summary_controller.dart';

/// Boutons d'action en bas de l'ecran de resume (Terminer / Passer).
class RideSummaryActions extends ConsumerWidget {
  const RideSummaryActions({
    super.key,
    required this.rideId,
    required this.onFinish,
  });

  final String rideId;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rideSummaryControllerProvider);
    return Column(
      children: [
        if (state.errorMessage != null) ...[
          Text(
            state.errorMessage!,
            style: AppTextStyles.small.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
        if (state.infoMessage != null) ...[
          Text(
            state.infoMessage!,
            style: AppTextStyles.small.copyWith(color: AppColors.success),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
        _buildSubmitButton(ref, state),
      ],
    );
  }

  Widget _buildSubmitButton(WidgetRef ref, RideSummaryState state) {
    final canSubmit = state.rating > 0 && !state.isSubmitting;
    return FrayaButton(
      label: 'Terminer',
      onPressed: canSubmit ? () => _submit(ref) : null,
      isLoading: state.isSubmitting,
      size: FrayaButtonSize.lg,
    );
  }

  Future<void> _submit(WidgetRef ref) async {
    final success = await ref
        .read(rideSummaryControllerProvider.notifier)
        .submitRating(rideId);
    if (!success) return;
    onFinish();
  }
}
