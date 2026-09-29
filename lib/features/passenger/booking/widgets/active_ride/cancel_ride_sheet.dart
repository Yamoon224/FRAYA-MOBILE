import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/extensions.dart';
import '../../../../../../shared/widgets/fraya_bottom_sheet_container.dart';
import '../../../../../../shared/widgets/selectable_option_tile.dart';
import '../../../../../../shared/widgets/sheet_handle.dart';
import '../../providers/booking_provider.dart';

class CancelRideSheet extends ConsumerStatefulWidget {
  const CancelRideSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CancelRideSheet(),
    );
  }

  @override
  ConsumerState<CancelRideSheet> createState() => _CancelRideSheetState();
}

class _CancelRideSheetState extends ConsumerState<CancelRideSheet> {
  String? _selectedReason;

  static const _reasons = [
    'Attente trop longue',
    'Le chauffeur n\'avance pas',
    'J\'ai trouve un autre moyen',
    'Mauvaise adresse saisie',
    'Urgence personnelle',
    'Autre',
  ];

  @override
  Widget build(BuildContext context) {
    return FrayaBottomSheetContainer(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Raison d\'annulation',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Pourquoi souhaitez-vous annuler cette course ?\n'
            'Plus de 3 annulations peuvent entraîner une suspension temporaire.',
            style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _reasons
            .map(
              (reason) => SelectableOptionTile(
                label: reason,
                selected: _selectedReason == reason,
                onTap: () => setState(() => _selectedReason = reason),
                activeColor: AppColors.error,
              ),
            )
            .toList(),
      ),
      footer: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedReason == null ? null : _confirmCancel,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                disabledBackgroundColor: context.colors.greyLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
              child: Text(
                'Confirmer l\'annulation',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Garder la course',
                style: AppTextStyles.body.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel() {
    Navigator.pop(context);
    ref
        .read(bookingFlowProvider.notifier)
        .cancelSearching(reason: _selectedReason);
  }
}
