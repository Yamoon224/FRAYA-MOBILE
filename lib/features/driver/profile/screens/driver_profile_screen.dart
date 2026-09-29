library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../shared/models/user_stats_view_data.dart';
import '../../../../../shared/widgets/app_snack_bar.dart';
import '../../../../../shared/widgets/fraya_button.dart';
import '../../auth/providers/driver_auth_provider.dart';
import '../../auth/providers/driver_submission_review_info.dart';
import '../../vehicle/widgets/driver_vehicle_info_update_sheet.dart';
import '../models/driver_profile_view_data.dart';
import '../providers/driver_profile_dependencies.dart';
import '../providers/driver_profile_document_review_provider.dart';
import '../providers/driver_profile_provider.dart';
import '../providers/driver_profile_view_data_resolver.dart';
import '../providers/driver_kyc_update_state.dart';
import '../widgets/driver_document_photo_viewer.dart';
import '../widgets/driver_kyc_update_sheet.dart';
import '../widgets/driver_kyc_update_result_sheet.dart';
import '../widgets/driver_profile_documents_section.dart';
import '../widgets/driver_profile_edit_dialog.dart';
import '../widgets/driver_profile_header.dart';
import '../widgets/driver_profile_info_card.dart';
import '../widgets/driver_profile_phone_change_dialog.dart';
import '../widgets/driver_profile_stats_grid.dart';
import '../widgets/driver_profile_vehicle_card.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(driverAuthProvider);
    final userData = authState.userData ?? const <String, dynamic>{};
    final viewData = DriverProfileViewDataResolver.fromUserData(userData);
    final documentReviewOverrides = ref.watch(
      driverProfileDocumentReviewProvider,
    );
    final documents = applyDriverProfileDocumentReviewOverrides(
      documents: viewData.documents,
      overrides: documentReviewOverrides,
    );
    final kycId = _extractKycId(userData);
    final vehicleId = DriverSubmissionReviewInfoResolver.fromUserData(
      userData,
    ).vehicleId;
    final stats = UserStatsViewData.fromMap(userData);

    final firstName =
        _asText(userData['firstNames']) ?? _asText(userData['firstName']);
    final lastName = _asText(userData['lastName']) ?? '';
    final name = ([firstName ?? 'Chauffeur', lastName]).join(' ').trim();
    final phone = _asText(userData['phoneNumber']) ?? '--';
    final email = _asText(userData['email']) ?? '--';
    final memberSince = _memberSince(_asText(userData['createdAt']));
    final photoUrl =
        _asText(userData['profilePhoto']) ??
        _asText(userData['photo']) ??
        _asText(userData['avatar']);

    final isUploading = ref.watch(
      driverProfileControllerProvider.select((s) => s.isSubmitting),
    );
    final backgroundColor = context.colors.background;
    final titleColor = context.colors.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _CircleIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text('Mon profil', style: AppTextStyles.h1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _CircleIconButton(
              icon: Icons.edit_outlined,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const DriverProfileEditDialog(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: context.responsiveBody(
          RefreshIndicator(
            onRefresh: () async {
              await ref.read(driverAuthProvider.notifier).refreshProfile();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                context.horizontalPagePadding,
                14,
                context.horizontalPagePadding,
                28,
              ),
              children: [
                DriverProfileHeader(
                  name: name,
                  stats: stats,
                  photoUrl: photoUrl,
                  rangeLabel: viewData.vehicle?.rangeLabel,
                  isUploading: isUploading,
                  onPhotoTap: isUploading
                      ? null
                      : () => _showPhotoPicker(context, ref),
                ),
                const SizedBox(height: 22),
                DriverProfileStatsGrid(
                  totalRidesLabel: stats.ridesCountLabel,
                  ratingLabel: stats.ratingLabel,
                ),
                const SizedBox(height: 22),
                Text('Informations personnelles', style: context.textH1),
                const SizedBox(height: 10),
                DriverProfileInfoCard(
                  phone: phone,
                  email: email,
                  memberSince: memberSince,
                ),
                if (viewData.vehicle != null) ...[
                  const SizedBox(height: 24),
                  Text('Mon véhicule', style: context.textH1),
                  const SizedBox(height: 10),
                  DriverProfileVehicleCard(
                    vehicle: viewData.vehicle!,
                    onEdit: vehicleId == null
                        ? null
                        : () => _showVehicleInfoUpdateSheet(context, vehicleId),
                  ),
                ],
                const SizedBox(height: 24),
                DriverProfileDocumentsSection(
                  documents: documents,
                  onDocumentTap: (doc) {
                    if (doc.documentUrl == null) {
                      AppSnackBar.showInfo(
                        context,
                        'Aucun document disponible',
                      );
                      return;
                    }
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => DriverDocumentPhotoViewer(document: doc),
                    );
                  },
                  onUpdateTap: kycId == null
                      ? null
                      : () => _showDocumentUpdateChoice(context, ref, kycId),
                ),
                const SizedBox(height: 16),
                FrayaButton(
                  label: 'Modifier mes informations',
                  leftIcon: Icons.edit_outlined,
                  variant: FrayaButtonVariant.primary,
                  size: FrayaButtonSize.lg,
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const DriverProfileEditDialog(),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const DriverProfilePhoneChangeDialog(),
                  ),
                  child: Text(
                    'Modifier mon numéro',
                    style: context.textH2.copyWith(color: titleColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPhotoPicker(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _pickAndUpload(context, ref, fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _pickAndUpload(context, ref, fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    WidgetRef ref, {
    required bool fromCamera,
  }) async {
    final picker = ref.read(driverProfilePhotoPickerProvider);
    final file = fromCamera
        ? await picker.pickFromCamera()
        : await picker.pickFromGallery();
    if (file == null) return;

    await ref
        .read(driverProfileControllerProvider.notifier)
        .updateProfilePhoto(filePath: file.path, fileName: file.name);
    if (!context.mounted) return;

    final state = ref.read(driverProfileControllerProvider);
    if (state.success) {
      ref.read(driverProfileControllerProvider.notifier).clearFeedback();
      AppSnackBar.showSuccess(context, 'Photo de profil mise à jour');
    } else if (state.errorMessage != null) {
      ref.read(driverProfileControllerProvider.notifier).clearFeedback();
      AppSnackBar.showError(context, state.errorMessage!);
    }
  }

  static Future<void> _showKycUpdateSheet(
    BuildContext context,
    WidgetRef ref,
    int kycId,
    DriverKycUpdateDocumentGroup documentGroup,
  ) async {
    final completion = await showModalBottomSheet<DriverKycUpdateCompletion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverKycUpdateSheet(
        kycId: kycId,
        mode: DriverKycUpdateMode.profileDocumentUpdate,
        documentGroup: documentGroup,
      ),
    );
    if (completion == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    ref
        .read(driverProfileDocumentReviewProvider.notifier)
        .markDocuments(
          completion.submittedDocuments,
          _documentStatusFromCompletion(completion),
        );
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverKycUpdateResultSheet(completion: completion),
    );
  }

  static Future<void> _showVehicleInfoUpdateSheet(
    BuildContext context,
    int vehicleId,
  ) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverVehicleInfoUpdateSheet(vehicleId: vehicleId),
    );
    if (updated == true && context.mounted) {
      AppSnackBar.showSuccess(
        context,
        'Infos vehicule mises a jour. Validation admin en cours.',
      );
    }
  }

  static Future<void> _showDocumentUpdateChoice(
    BuildContext context,
    WidgetRef ref,
    int kycId,
  ) async {
    final choice = await showDialog<DriverKycUpdateDocumentGroup>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Quels documents modifier ?',
          textAlign: TextAlign.center,
          style: AppTextStyles.h2,
        ),
        content: Text(
          'Choisissez le type de documents que vous souhaitez consulter ou mettre à jour.',
          textAlign: TextAlign.center,
          style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  style: _documentChoiceButtonStyle(isPrimary: false, context: dialogContext),
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(DriverKycUpdateDocumentGroup.vehicle),
                  child: const Text('Documents véhicule'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  style: _documentChoiceButtonStyle(isPrimary: true, context: dialogContext),
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(DriverKycUpdateDocumentGroup.personal),
                  child: const Text('Documents personnels'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) {
      return;
    }
    await _showKycUpdateSheet(context, ref, kycId, choice);
  }

  static int? _extractKycId(Map<String, dynamic> userData) {
    final kycs = userData['kycs'];
    if (kycs is List && kycs.isNotEmpty) {
      final id = kycs.first['id'];
      if (id is int) return id;
      if (id != null) return int.tryParse(id.toString());
    }
    return null;
  }

  static String? _asText(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  static String _memberSince(String? createdAt) {
    final date = DateTime.tryParse(createdAt ?? '');
    if (date == null) return '--';
    const months = <String>[
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

ButtonStyle _documentChoiceButtonStyle({required bool isPrimary, required BuildContext context}) {
  return TextButton.styleFrom(
    minimumSize: const Size.fromHeight(54),
    backgroundColor: isPrimary ? AppColors.primary : context.colors.surface,
    foregroundColor: context.colors.textPrimary,
    textStyle: AppTextStyles.button,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      side: BorderSide(
        color: isPrimary ? AppColors.primaryDark : context.colors.greyLight,
        width: 1.5,
      ),
    ),
  );
}

DriverProfileDocumentStatus _documentStatusFromCompletion(
  DriverKycUpdateCompletion completion,
) {
  if (completion.isApproved) {
    return DriverProfileDocumentStatus.valid;
  }
  if (completion.isRejected) {
    return DriverProfileDocumentStatus.rejected;
  }
  return DriverProfileDocumentStatus.pending;
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated,
        shape: BoxShape.circle,
        boxShadow: context.colors.isDark ? null : AppColors.shadowSm,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: context.colors.textPrimary,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
