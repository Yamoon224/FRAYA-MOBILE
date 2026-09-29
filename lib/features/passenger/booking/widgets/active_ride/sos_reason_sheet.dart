import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/extensions.dart';
import '../../../../../../shared/providers/location_provider.dart';
import '../../../../../../shared/widgets/app_snack_bar.dart';
import '../../../../../../shared/widgets/fraya_bottom_sheet_container.dart';
import '../../../../../../shared/widgets/selectable_option_tile.dart';
import '../../../../../../shared/widgets/sheet_handle.dart';
import '../../providers/sos_alert_controller.dart';

class SosReasonSheet extends ConsumerStatefulWidget {
  const SosReasonSheet({super.key, required this.rideId});

  final String rideId;

  static void show(BuildContext context, String rideId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SosReasonSheet(rideId: rideId),
    );
  }

  @override
  ConsumerState<SosReasonSheet> createState() => _SosReasonSheetState();
}

class _SosReasonSheetState extends ConsumerState<SosReasonSheet> {
  String? _selectedReason;

  static const _reasons = [
    'Je me sens en danger',
    'Comportement agressif du chauffeur',
    'Itinéraire incorrect / Mauvaise direction',
    'Accident ou incident',
    'Probleme medical',
    'Tentative de vol',
    'Autre urgence',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sosAlertControllerProvider);

    return FrayaBottomSheetContainer(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppTheme.spacingLg),
          Row(
            children: [
              const Icon(Icons.sos_rounded, color: AppColors.error, size: 22),
              const SizedBox(width: 8),
              Text(
                'Type d\'urgence',
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Precisez la nature de votre urgence pour alerter le support.',
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
            child: ElevatedButton.icon(
              onPressed: (_selectedReason == null || state.isSubmitting)
                  ? null
                  : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                disabledBackgroundColor: context.colors.greyLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
              icon: state.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sos_rounded),
              label: Text(
                state.isSubmitting ? 'Envoi en cours...' : 'Envoyer l\'alerte SOS',
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
                'Annuler',
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

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    final liveLocation = ref.read(currentLocationProvider).asData?.value;
    final locationService = ref.read(locationServiceProvider);
    final location =
        liveLocation ??
        await locationService.getCurrentPosition() ??
        await locationService.getLastKnownPosition();
    final success = await ref.read(sosAlertControllerProvider.notifier).submit(
          rideId: widget.rideId,
          lat: location?.latitude,
          lng: location?.longitude,
          reason: _selectedReason,
        );
    if (!mounted) return;
    Navigator.pop(context);
    if (success) {
      AppSnackBar.showSuccess(context, 'Alerte SOS envoyee avec succes.');
      return;
    }

    final error = ref.read(sosAlertControllerProvider).errorMessage ??
        'Impossible d\'envoyer l\'alerte SOS.';
    AppSnackBar.showError(context, error);
  }
}
