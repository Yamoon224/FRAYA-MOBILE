library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../domain/models/driver_kyc_document_type.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../../../driver/auth/providers/driver_auth_provider.dart';
import '../providers/driver_kyc_update_notifier.dart';
import '../providers/driver_kyc_update_state.dart';
import '../providers/driver_profile_view_data_resolver.dart';
import 'driver_kyc_update_document_tile.dart';

class DriverKycUpdateSheet extends ConsumerStatefulWidget {
  const DriverKycUpdateSheet({
    super.key,
    required this.kycId,
    this.rejectionReason,
    this.mode = DriverKycUpdateMode.onboardingCorrection,
    this.documentGroup = DriverKycUpdateDocumentGroup.personal,
  });

  final int kycId;
  final String? rejectionReason;
  final DriverKycUpdateMode mode;
  final DriverKycUpdateDocumentGroup documentGroup;

  @override
  ConsumerState<DriverKycUpdateSheet> createState() =>
      _DriverKycUpdateSheetState();
}

class _DriverKycUpdateSheetState extends ConsumerState<DriverKycUpdateSheet> {
  @override
  Widget build(BuildContext context) {
    ref.listen<DriverKycUpdateState>(driverKycUpdateProvider, (_, next) {
      if (!mounted) return;
      if (next.success) {
        final completion = next.completion;
        ref.read(driverKycUpdateProvider.notifier).clearFeedback();
        Navigator.of(context).pop(completion);
        if (widget.mode == DriverKycUpdateMode.onboardingCorrection) {
          AppSnackBar.showSuccess(context, 'Documents mis à jour avec succès');
        }
      } else if (next.errorMessage != null) {
        ref.read(driverKycUpdateProvider.notifier).clearFeedback();
        AppSnackBar.showError(context, next.errorMessage!);
      }
    });

    final isSubmitting = ref.watch(
      driverKycUpdateProvider.select((s) => s.isSubmitting),
    );
    final isProcessing = ref.watch(
      driverKycUpdateProvider.select((s) => s.processingDocuments.isNotEmpty),
    );
    final canSubmit = ref.watch(
      driverKycUpdateProvider.select(
        (s) => s.canSubmitFor(widget.documentGroup),
      ),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => _SheetContent(
        scrollController: scrollController,
        kycId: widget.kycId,
        rejectionReason: widget.rejectionReason,
        mode: widget.mode,
        documentGroup: widget.documentGroup,
        isSubmitting: isSubmitting,
        isProcessing: isProcessing,
        canSubmit: canSubmit,
      ),
    );
  }
}

class _SheetContent extends ConsumerWidget {
  const _SheetContent({
    required this.scrollController,
    required this.kycId,
    required this.rejectionReason,
    required this.mode,
    required this.documentGroup,
    required this.isSubmitting,
    required this.isProcessing,
    required this.canSubmit,
  });

  final ScrollController scrollController;
  final int kycId;
  final String? rejectionReason;
  final DriverKycUpdateMode mode;
  final DriverKycUpdateDocumentGroup documentGroup;
  final bool isSubmitting;
  final bool isProcessing;
  final bool canSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData =
        ref.watch(driverAuthProvider.select((s) => s.userData)) ?? {};
    final isVehicleGroup =
        documentGroup == DriverKycUpdateDocumentGroup.vehicle;
    final documents = isVehicleGroup
        ? driverKycVehicleDocuments
        : driverKycUpdateDocuments;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _SheetHandle(),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(_title(documentGroup), style: AppTextStyles.h1),
                const SizedBox(height: 4),
                Text(_description(documentGroup), style: AppTextStyles.small),
                if (rejectionReason?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _RejectionReasonBox(message: rejectionReason!.trim()),
                ],
                const SizedBox(height: 20),
                _SectionHeader(title: _sectionTitle(documentGroup)),
                const SizedBox(height: 10),
                ...documents.map(
                  (type) => DriverKycUpdateDocumentTile(
                    type: type,
                    enabled: !isSubmitting && !isProcessing,
                    canReplace: true,
                    existingUrl:
                        DriverProfileViewDataResolver.resolveBackendFieldUrl(
                          userData,
                          type.backendField,
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                FrayaButton(
                  label: isProcessing
                      ? 'Optimisation en cours...'
                      : isSubmitting
                      ? 'Envoi en cours...'
                      : 'Confirmer la mise à jour',
                  variant: FrayaButtonVariant.primary,
                  size: FrayaButtonSize.lg,
                  isLoading: isSubmitting,
                  onPressed: canSubmit
                      ? () => ref
                            .read(driverKycUpdateProvider.notifier)
                            .submit(
                              kycId,
                              mode: mode,
                              documentGroup: documentGroup,
                            )
                      : null,
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'Annuler',
                      style: AppTextStyles.h2.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _title(DriverKycUpdateDocumentGroup group) {
  return switch (group) {
    DriverKycUpdateDocumentGroup.personal => 'Mettre à jour mes documents',
    DriverKycUpdateDocumentGroup.vehicle => 'Documents véhicule',
  };
}

String _description(DriverKycUpdateDocumentGroup group) {
  return switch (group) {
    DriverKycUpdateDocumentGroup.personal =>
      'Consultez vos documents soumis ou remplacez ceux qui doivent être modifiés.',
    DriverKycUpdateDocumentGroup.vehicle =>
      'Ajoutez ou remplacez les documents de votre véhicule avant de renvoyer le dossier.',
  };
}

String _sectionTitle(DriverKycUpdateDocumentGroup group) {
  return switch (group) {
    DriverKycUpdateDocumentGroup.personal => 'Documents personnels',
    DriverKycUpdateDocumentGroup.vehicle => 'Documents véhicule',
  };
}

class _RejectionReasonBox extends StatelessWidget {
  const _RejectionReasonBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.greyLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.greyExtraLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(title, style: AppTextStyles.h3),
    );
  }
}
