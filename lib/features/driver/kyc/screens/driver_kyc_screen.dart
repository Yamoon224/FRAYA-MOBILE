library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/driver_kyc_document_file.dart';
import '../../../../domain/models/driver_kyc_document_type.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../../../../shared/widgets/settings/logout_confirmation_dialog.dart';
import '../../auth/providers/driver_admin_status_gate.dart';
import '../../auth/providers/driver_auth_provider.dart';
// import '../../auth/providers/driver_kyc_vehicle_docs_resolver.dart'; // désactivé temporairement (voir b70ad34)
import '../../auth/providers/driver_submission_review_info.dart';
import '../../profile/widgets/driver_kyc_update_sheet.dart';
import '../../vehicle/widgets/driver_vehicle_info_update_sheet.dart';
import '../../vehicle/widgets/driver_vehicle_update_sheet.dart';
import '../providers/driver_kyc_dependencies.dart';
import '../providers/driver_kyc_provider.dart';
import '../widgets/driver_document_picker_tile.dart';
import '../widgets/driver_document_source_sheet.dart';
import '../widgets/driver_kyc_deadline_notice.dart';
import '../widgets/driver_kyc_section_card.dart';
import '../widgets/driver_kyc_status_banner.dart';

class DriverKycScreen extends ConsumerStatefulWidget {
  const DriverKycScreen({super.key});

  @override
  ConsumerState<DriverKycScreen> createState() => _DriverKycScreenState();
}

class _DriverKycScreenState extends ConsumerState<DriverKycScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen(driverKycFormProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppSnackBar.showError(context, next.errorMessage!);
      }
      if (next.lastSubmittedAt != null &&
          next.lastSubmittedAt != previous?.lastSubmittedAt) {
        AppSnackBar.showSuccess(
          context,
          'Dossier KYC envoyé. Validation admin en cours.',
        );
      }
    });

    final authState = ref.watch(driverAuthProvider);
    final formState = ref.watch(driverKycFormProvider);
    final gate = DriverAdminStatusGate.fromUserData(authState.userData);
    final reviewInfo = DriverSubmissionReviewInfoResolver.fromUserData(
      authState.userData,
    );
    // Désactivé temporairement (voir b70ad34)
    // final vehicleKycDocs = DriverKycVehicleDocsResolver.resolve(
    //   authState.userData,
    // );
    // final needsVehicleCompletion =
    //     (gate.isKycPending || gate.isKycApproved) &&
    //     vehicleKycDocs.needsVehicleCompletion &&
    //     reviewInfo.kycId != null;
    final isPending = gate.isKycPending;
    final canUpdateRejectedKyc = gate.isKycRejected && reviewInfo.kycId != null;
    final backgroundColor = context.colors.background;
    final secondaryTextColor = context.colors.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: context.responsiveBody(
          SingleChildScrollView(
            padding: context.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: context.colors.textPrimary,
                      tooltip: 'Retour',
                      onPressed: () => _goBack(context),
                    ),
                    const SizedBox(width: 4),
                    Image.asset(
                      'assets/images/logo_fraya.png',
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXl),
                Text(
                  'Verification chauffeur',
                  style: context.textH1.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Ajoutez vos documents chauffeur pour lancer la validation admin.',
                  style: context.textBody.copyWith(color: secondaryTextColor),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                DriverKycStatusBanner(
                  title: _bannerTitle(gate),
                  message: _bannerMessage(gate, reviewInfo),
                  icon: _bannerIcon(gate),
                  backgroundColor: _bannerBackground(gate),
                  foregroundColor: _bannerForeground(gate),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                // Désactivé temporairement (voir b70ad34)
                // if (needsVehicleCompletion) ...[
                //   _VehicleCompletionCard(
                //     missingDocuments: vehicleKycDocs.missingDocuments,
                //     onUpdateVehicle: () =>
                //         _showVehicleUpdateSheet(reviewInfo.kycId!),
                //     onRefreshStatus: () =>
                //         ref.read(driverAuthProvider.notifier).refreshProfile(),
                //   ),
                // ] else
                if (isPending) ...[
                  _PendingReviewCard(
                    onRefreshStatus: () =>
                        ref.read(driverAuthProvider.notifier).refreshProfile(),
                  ),
                ] else if (canUpdateRejectedKyc) ...[
                  _RejectedReviewCard(
                    reason: reviewInfo.kycRejectionReason,
                    canUpdateVehicleInfo: reviewInfo.vehicleId != null,
                    canUpdateVehicleDocuments: reviewInfo.kycId != null,
                    onUpdateDocuments: () =>
                        _showKycUpdateSheet(reviewInfo.kycId!),
                    onUpdateVehicleInfo: () =>
                        _showVehicleInfoUpdateSheet(reviewInfo.vehicleId!),
                    onUpdateVehicleDocuments: () =>
                        _showVehicleDocumentsUpdateSheet(reviewInfo.kycId!),
                    onRefreshStatus: () =>
                        ref.read(driverAuthProvider.notifier).refreshProfile(),
                  ),
                ] else ...[
                  DriverKycSectionCard(
                    title: 'Documents chauffeur',
                    subtitle:
                        'Permis, selfie avec permis et casier judiciaire.',
                    children: _buildSectionTiles(
                      documents: driverKycDriverDocuments,
                      isSubmitting: formState.isSubmitting,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  const DriverKycDeadlineNotice(),
                  const SizedBox(height: AppTheme.spacingLg),
                  FrayaButton(
                    label: 'Soumettre le dossier',
                    onPressed: formState.canSubmit
                        ? ref.read(driverKycFormProvider.notifier).submit
                        : null,
                    isLoading: formState.isSubmitting,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  FrayaButton(
                    label: 'Continuer plus tard',
                    variant: FrayaButtonVariant.ghost,
                    onPressed: formState.isSubmitting
                        ? null
                        : () => _goBack(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSectionTiles({
    required List<DriverKycDocumentType> documents,
    required bool isSubmitting,
  }) {
    final formState = ref.watch(driverKycFormProvider);
    final selectedDocuments = formState.documents;
    return documents
        .map(
          (type) => DriverDocumentPickerTile(
            type: type,
            document: selectedDocuments[type],
            enabled:
                !isSubmitting && !formState.processingDocuments.contains(type),
            isProcessing: formState.processingDocuments.contains(type),
            isOptional: type == DriverKycDocumentType.photoCasier,
            onSelect: () => _pickDocument(type),
            onRemove: () =>
                ref.read(driverKycFormProvider.notifier).removeDocument(type),
          ),
        )
        .toList();
  }

  Future<void> _goBack(BuildContext context) async {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final confirmed = await showLogoutConfirmationDialog(context);
    if (!confirmed || !mounted) return;
    await ref.read(driverAuthProvider.notifier).logout();
  }

  Future<void> _pickDocument(DriverKycDocumentType type) async {
    final cameraAvailable =
        ImagePicker().supportsImageSource(ImageSource.camera);
    if (!mounted) return;

    final source = await DriverDocumentSourceSheet.show(
      context,
      cameraAvailable: cameraAvailable,
    );
    if (source == null || !mounted) {
      return;
    }

    final picker = ref.read(driverKycDocumentPickerProvider);
    DriverKycDocumentFile? document;
    try {
      document = await picker.pick(source);
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Impossible d\'accéder à la caméra.',
        );
      }
      return;
    }
    if (document == null || !mounted) {
      return;
    }

    await ref.read(driverKycFormProvider.notifier).setDocument(type, document);
  }

  void _showVehicleDocumentsUpdateSheet(int kycId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverVehicleUpdateSheet(kycId: kycId),
    );
  }

  Future<void> _showVehicleInfoUpdateSheet(int vehicleId) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverVehicleInfoUpdateSheet(vehicleId: vehicleId),
    );
    if (updated == true && mounted) {
      AppSnackBar.showSuccess(
        context,
        'Infos vehicule mises a jour. Validation admin en cours.',
      );
    }
  }

  void _showKycUpdateSheet(int kycId) {
    final reviewInfo = DriverSubmissionReviewInfoResolver.fromUserData(
      ref.read(driverAuthProvider).userData,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverKycUpdateSheet(
        kycId: kycId,
        rejectionReason: reviewInfo.kycRejectionReason,
      ),
    );
  }

  String _bannerTitle(DriverAdminStatusResult gate) {
    if (gate.isKycRejected) {
      return 'Dossier à renvoyer';
    }
    if (gate.isKycPending) {
      return 'Validation admin en cours';
    }
    return 'Soumission obligatoire';
  }

  String _bannerMessage(
    DriverAdminStatusResult gate,
    DriverSubmissionReviewInfo reviewInfo,
  ) {
    if (gate.isKycRejected) {
      final reason = reviewInfo.kycRejectionReason;
      if (reason != null) return reason;
      return 'Votre précédente soumission a été rejetée. Merci de remplacer les documents concernés.';
    }
    if (gate.isKycPending) {
      return 'Votre dossier KYC a bien été envoyé. Nous attendons maintenant la validation d\'un administrateur.';
    }
    return 'Le volet chauffeur reste bloqué tant que ce dossier n\'a pas été soumis.';
  }

  IconData _bannerIcon(DriverAdminStatusResult gate) {
    if (gate.isKycRejected) {
      return Icons.error_outline_rounded;
    }
    if (gate.isKycPending) {
      return Icons.hourglass_top_rounded;
    }
    return Icons.assignment_outlined;
  }

  Color _bannerBackground(DriverAdminStatusResult gate) {
    if (gate.isKycRejected) {
      return AppColors.error.withValues(alpha: 0.12);
    }
    return AppColors.infoBackground;
  }

  Color _bannerForeground(DriverAdminStatusResult gate) {
    if (gate.isKycRejected) {
      return AppColors.error;
    }
    return AppColors.infoText;
  }
}

// Désactivé temporairement (voir b70ad34) — réactiver si on réintroduit l'étape docs véhicule KYC
// class _VehicleCompletionCard extends StatelessWidget {
//   const _VehicleCompletionCard({
//     required this.missingDocuments,
//     required this.onUpdateVehicle,
//     required this.onRefreshStatus,
//   });
//
//   final Set<DriverKycDocumentType> missingDocuments;
//   final VoidCallback onUpdateVehicle;
//   final VoidCallback onRefreshStatus;
//
//   @override
//   Widget build(BuildContext context) {
//     final missingLabels = missingDocuments.map((type) => type.label).join(', ');
//
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(AppTheme.spacingLg),
//       decoration: BoxDecoration(
//         color: AppColors.infoBackground,
//         borderRadius: BorderRadius.circular(AppTheme.radiusLg),
//         border: Border.all(color: AppColors.infoText.withValues(alpha: 0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Documents véhicule requis',
//             style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
//           ),
//           const SizedBox(height: AppTheme.spacingSm),
//           Text(
//             missingLabels.isEmpty
//                 ? 'Vos documents chauffeur sont envoyés. Complétez maintenant les documents du véhicule.'
//                 : 'Vos documents chauffeur sont envoyés. Ajoutez les pièces véhicule manquantes : $missingLabels.',
//             style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
//           ),
//           const SizedBox(height: AppTheme.spacingMd),
//           FrayaButton(
//             label: 'Compléter le véhicule',
//             leftIcon: Icons.directions_car_outlined,
//             onPressed: onUpdateVehicle,
//           ),
//           const SizedBox(height: AppTheme.spacingSm),
//           FrayaButton(
//             label: 'Actualiser mon statut',
//             variant: FrayaButtonVariant.outline,
//             leftIcon: Icons.refresh_rounded,
//             onPressed: onRefreshStatus,
//           ),
//         ],
//       ),
//     );
//   }
// }

class _RejectedReviewCard extends StatelessWidget {
  const _RejectedReviewCard({
    required this.reason,
    required this.canUpdateVehicleInfo,
    required this.canUpdateVehicleDocuments,
    required this.onUpdateDocuments,
    required this.onUpdateVehicleInfo,
    required this.onUpdateVehicleDocuments,
    required this.onRefreshStatus,
  });

  final String? reason;
  final bool canUpdateVehicleInfo;
  final bool canUpdateVehicleDocuments;
  final VoidCallback onUpdateDocuments;
  final VoidCallback onUpdateVehicleInfo;
  final VoidCallback onUpdateVehicleDocuments;
  final VoidCallback onRefreshStatus;

  @override
  Widget build(BuildContext context) {
    final message = reason?.trim().isNotEmpty == true
        ? reason!.trim()
        : 'Remplacez uniquement les documents concernés par le rejet, puis renvoyez le dossier.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Correction demandée',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          FrayaButton(
            label: 'Corriger le KYC',
            leftIcon: Icons.upload_file_outlined,
            onPressed: onUpdateDocuments,
          ),
          if (canUpdateVehicleInfo) ...[
            const SizedBox(height: AppTheme.spacingSm),
            FrayaButton(
              label: 'Corriger les infos véhicule',
              leftIcon: Icons.directions_car_outlined,
              variant: FrayaButtonVariant.outline,
              onPressed: onUpdateVehicleInfo,
            ),
          ],
          if (canUpdateVehicleDocuments) ...[
            const SizedBox(height: AppTheme.spacingSm),
            FrayaButton(
              label: 'Corriger les documents véhicule',
              leftIcon: Icons.upload_file_outlined,
              variant: FrayaButtonVariant.outline,
              onPressed: onUpdateVehicleDocuments,
            ),
          ],
          const SizedBox(height: AppTheme.spacingSm),
          FrayaButton(
            label: 'Actualiser mon statut',
            variant: FrayaButtonVariant.outline,
            leftIcon: Icons.refresh_rounded,
            onPressed: onRefreshStatus,
          ),
        ],
      ),
    );
  }
}

class _PendingReviewCard extends StatelessWidget {
  const _PendingReviewCard({required this.onRefreshStatus});

  final VoidCallback onRefreshStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: context.colors.greyExtraLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dossier transmis',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Vous ne pouvez pas encore accéder à l\'étape véhicule ou au home chauffeur tant que le KYC reste en attente.',
            style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          FrayaButton(
            label: 'Actualiser mon statut',
            variant: FrayaButtonVariant.outline,
            leftIcon: Icons.refresh_rounded,
            onPressed: onRefreshStatus,
          ),
        ],
      ),
    );
  }
}
