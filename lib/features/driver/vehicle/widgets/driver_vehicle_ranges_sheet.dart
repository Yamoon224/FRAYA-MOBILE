library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/vehicle_ui_utils.dart';
import '../../../../domain/models/driver_vehicle_document_type.dart';
import '../../kyc/providers/driver_kyc_dependencies.dart';
import '../../kyc/widgets/driver_document_source_sheet.dart';
import '../providers/driver_vehicle_ranges_provider.dart';
import 'driver_vehicle_document_picker_tile.dart';
import 'driver_vehicle_secondary_range_selector.dart';

/// Feuille « Gérer mes gammes » : retirer sa seconde gamme, la remplacer par une gamme déjà couverte
/// (modification immédiate) ou en demander une supérieure (cinq photos, revue par un administrateur).
/// Se ferme avec le [DriverVehicleRangesOutcome] en cas de succès.
class DriverVehicleRangesSheet extends ConsumerWidget {
  const DriverVehicleRangesSheet({
    super.key,
    required this.vehicleId,
    required this.primaryRange,
    required this.secondaryRange,
  });

  final int vehicleId;
  final String primaryRange;
  final String? secondaryRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = DriverVehicleRangesArgs(
      vehicleId: vehicleId,
      primaryRange: primaryRange,
      currentSecondaryRange: secondaryRange,
    );
    final state = ref.watch(driverVehicleRangesProvider(args));
    final notifier = ref.read(driverVehicleRangesProvider(args).notifier);

    ref.listen<DriverVehicleRangesState>(driverVehicleRangesProvider(args), (
      previous,
      next,
    ) {
      if (next.outcome != null && previous?.outcome != next.outcome) {
        Navigator.of(context).pop(next.outcome);
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppTheme.spacingLg,
        right: AppTheme.spacingLg,
        top: AppTheme.spacingLg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLg,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mes gammes', style: AppTextStyles.h2),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Gamme principale : ${VehicleUiUtils.rangeLabel(state.primaryRange)}',
                style: AppTextStyles.small,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              DriverVehicleSecondaryRangeSelector(
                primaryRange: state.primaryRange,
                selectedSecondaryRange: state.selectedSecondaryRange,
                enabled: !state.isSubmitting,
                onSelected: notifier.selectSecondaryRange,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _ModeExplanation(state: state),
              if (state.requiresReview) ...[
                const SizedBox(height: AppTheme.spacingMd),
                for (final type in vehicleRangePhotoTypes) ...[
                  DriverVehicleDocumentPickerTile(
                    type: type,
                    document: state.photos[type],
                    enabled: !state.isSubmitting,
                    onSelect: () => _pickPhoto(context, ref, notifier, type),
                    onRemove: () => notifier.removePhoto(type),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                ],
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  state.errorMessage!,
                  style: AppTextStyles.small.copyWith(color: Colors.red),
                ),
              ],
              const SizedBox(height: AppTheme.spacingMd),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.canSubmit ? notifier.submit : null,
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          state.requiresReview
                              ? 'Envoyer la demande'
                              : 'Enregistrer',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(
    BuildContext context,
    WidgetRef ref,
    DriverVehicleRangesNotifier notifier,
    DriverVehicleDocumentType type,
  ) async {
    final cameraAvailable = ImagePicker().supportsImageSource(
      ImageSource.camera,
    );
    if (!context.mounted) return;
    final source = await DriverDocumentSourceSheet.show(
      context,
      cameraAvailable: cameraAvailable,
    );
    if (source == null || !context.mounted) return;
    try {
      final document = await ref.read(driverKycDocumentPickerProvider).pick(source);
      if (document != null) notifier.setPhoto(type, document);
    } catch (_) {
      // Une photo non récupérée n'interrompt pas la saisie : le chauffeur peut réessayer.
    }
  }
}

class _ModeExplanation extends StatelessWidget {
  const _ModeExplanation({required this.state});

  final DriverVehicleRangesState state;

  @override
  Widget build(BuildContext context) {
    final text = !state.hasChange
        ? 'Choisissez une seconde gamme, ou « Aucune » pour la retirer.'
        : state.requiresReview
        ? 'Cette gamme est supérieure à celle de votre véhicule : ajoutez les cinq photos ci-dessous. '
              'Un administrateur examinera votre demande ; votre véhicule reste en service pendant ce temps.'
        : state.selectedSecondaryRange == null
        ? 'La seconde gamme sera retirée tout de suite.'
        : 'Cette gamme est déjà couverte par votre véhicule : la modification est immédiate.';
    return Text(text, style: AppTextStyles.small);
  }
}
