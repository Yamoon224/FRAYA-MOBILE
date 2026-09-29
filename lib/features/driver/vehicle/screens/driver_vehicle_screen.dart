library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/driver_vehicle_document_type.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../../../../shared/widgets/settings/logout_confirmation_dialog.dart';
import '../../auth/providers/driver_admin_status_gate.dart';
import '../../auth/providers/driver_auth_provider.dart';
import '../../auth/providers/driver_submission_review_info.dart';
import '../../kyc/providers/driver_kyc_dependencies.dart';
import '../../kyc/widgets/driver_document_source_sheet.dart';
import '../../kyc/widgets/driver_kyc_section_card.dart';
import '../../kyc/widgets/driver_kyc_status_banner.dart';
import '../providers/driver_vehicle_form_provider.dart';
import '../providers/driver_vehicle_form_state.dart';
import '../widgets/driver_vehicle_documents_section.dart';
import '../widgets/driver_vehicle_info_update_sheet.dart';
import '../widgets/driver_vehicle_info_section.dart';
import '../widgets/driver_vehicle_status_resolver.dart';
import '../widgets/driver_vehicle_update_sheet.dart';

enum _VehicleStep { info, documents }

class DriverVehicleScreen extends ConsumerStatefulWidget {
  const DriverVehicleScreen({super.key});

  @override
  ConsumerState<DriverVehicleScreen> createState() =>
      _DriverVehicleScreenState();
}

class _DriverVehicleScreenState extends ConsumerState<DriverVehicleScreen> {
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _licensePlateController = TextEditingController();

  _VehicleStep _step = _VehicleStep.info;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Future<void> _goBack(BuildContext context) async {
    if (_step == _VehicleStep.documents) {
      setState(() => _step = _VehicleStep.info);
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    final confirmed = await showLogoutConfirmationDialog(context);
    if (!confirmed || !mounted) return;
    await ref.read(driverAuthProvider.notifier).logout();
  }

  void _goToDocuments() {
    setState(() => _step = _VehicleStep.documents);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(driverVehicleFormProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppSnackBar.showError(context, next.errorMessage!);
      }
      if (next.lastSubmittedAt != null &&
          next.lastSubmittedAt != previous?.lastSubmittedAt) {
        AppSnackBar.showSuccess(
          context,
          'Véhicule envoyé. Validation admin en cours.',
        );
      }
    });

    final authState = ref.watch(driverAuthProvider);
    final formState = ref.watch(driverVehicleFormProvider);
    final gate = DriverAdminStatusGate.fromUserData(authState.userData);
    final reviewInfo = DriverSubmissionReviewInfoResolver.fromUserData(
      authState.userData,
    );
    final viewData = DriverVehicleStatusResolver.resolve(
      context,
      gate,
      vehicleRejectionReason: reviewInfo.vehicleRejectionReason,
    );
    final canPatchVehicleInfo =
        gate.isVehicleRejected && reviewInfo.vehicleId != null;
    final canUpdateVehicleDocuments =
        gate.isVehicleRejected && reviewInfo.kycId != null;
    _syncControllers(formState);
    final backgroundColor = context.colors.background;
    final secondaryTextColor = context.colors.textSecondary;
    final canGoNextStep =
        formState.brand.trim().isNotEmpty &&
        formState.model.trim().isNotEmpty &&
        formState.year.trim().isNotEmpty &&
        formState.color.trim().isNotEmpty &&
        formState.licensePlate.trim().isNotEmpty;

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
                  'Validation véhicule',
                  style: context.textH1.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Ajoutez les informations du véhicule et les pièces demandées pour activer votre profil chauffeur.',
                  style: context.textBody.copyWith(color: secondaryTextColor),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                DriverKycStatusBanner(
                  title: viewData.title,
                  message: viewData.message,
                  icon: viewData.icon,
                  backgroundColor: viewData.backgroundColor,
                  foregroundColor: viewData.foregroundColor,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                if (_step == _VehicleStep.info) ...[
                  DriverKycSectionCard(
                    title: 'Informations du véhicule',
                    subtitle:
                        'Renseignez les informations telles qu\'elles apparaissent sur vos documents et choisissez la gamme associée.',
                    children: [
                      DriverVehicleInfoSection(
                        brandController: _brandController,
                        modelController: _modelController,
                        yearController: _yearController,
                        colorController: _colorController,
                        licensePlateController: _licensePlateController,
                        selectedRange: formState.selectedRange,
                        airConditioning: formState.airConditioning,
                        enabled:
                            viewData.isEditable &&
                            !formState.isSubmitting &&
                            !canPatchVehicleInfo,
                        onBrandChanged: ref
                            .read(driverVehicleFormProvider.notifier)
                            .setBrand,
                        onModelChanged: ref
                            .read(driverVehicleFormProvider.notifier)
                            .setModel,
                        onYearChanged: ref
                            .read(driverVehicleFormProvider.notifier)
                            .setYear,
                        onColorChanged: ref
                            .read(driverVehicleFormProvider.notifier)
                            .setColor,
                        onLicensePlateChanged: ref
                            .read(driverVehicleFormProvider.notifier)
                            .setLicensePlate,
                        onRangeChanged: ref
                            .read(driverVehicleFormProvider.notifier)
                            .setRange,
                        onAirConditioningChanged: ref
                            .read(driverVehicleFormProvider.notifier)
                            .setAirConditioning,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  if (canPatchVehicleInfo) ...[
                    FrayaButton(
                      label: 'Corriger les infos vehicule',
                      leftIcon: Icons.directions_car_outlined,
                      onPressed: () =>
                          _showVehicleInfoUpdateSheet(reviewInfo.vehicleId!),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    FrayaButton(
                      label: 'Actualiser le statut',
                      leftIcon: Icons.refresh_rounded,
                      variant: FrayaButtonVariant.outline,
                      onPressed: ref
                          .read(driverAuthProvider.notifier)
                          .refreshProfile,
                    ),
                  ] else ...[
                    FrayaButton(
                      label: 'Suivant',
                      onPressed:
                          canGoNextStep && !formState.isSubmitting
                              ? _goToDocuments
                              : null,
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
                ] else ...[
                  DriverKycSectionCard(
                    title: 'Documents véhicule',
                    subtitle:
                        'Ajoutez les cinq photos du véhicule, la carte grise, l\'assurance et la visite technique.',
                    children: [
                      DriverVehicleDocumentsSection(
                        documents: formState.documents,
                        processingDocuments: formState.processingDocuments,
                        enabled:
                            viewData.isEditable &&
                            !formState.isSubmitting &&
                            !canPatchVehicleInfo,
                        onSelect: _pickDocument,
                        onRemove: ref
                            .read(driverVehicleFormProvider.notifier)
                            .removeDocument,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  if (canPatchVehicleInfo) ...[
                    if (canUpdateVehicleDocuments) ...[
                      FrayaButton(
                        label: 'Corriger les documents vehicule',
                        leftIcon: Icons.upload_file_outlined,
                        onPressed: () =>
                            _showVehicleDocumentsUpdateSheet(reviewInfo.kycId!),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                    ],
                    FrayaButton(
                      label: 'Actualiser le statut',
                      leftIcon: Icons.refresh_rounded,
                      variant: FrayaButtonVariant.outline,
                      onPressed: ref
                          .read(driverAuthProvider.notifier)
                          .refreshProfile,
                    ),
                  ] else ...[
                    FrayaButton(
                      label: viewData.buttonLabel,
                      onPressed: formState.isSubmitting
                          ? null
                          : viewData.isEditable
                          ? ref
                                .read(driverVehicleFormProvider.notifier)
                                .submit
                          : ref
                                .read(driverAuthProvider.notifier)
                                .refreshProfile,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDocument(DriverVehicleDocumentType type) async {
    final cameraAvailable =
        ImagePicker().supportsImageSource(ImageSource.camera);
    if (!mounted) return;

    final source = await DriverDocumentSourceSheet.show(
      context,
      cameraAvailable: cameraAvailable,
    );
    if (source == null || !mounted) return;

    final picker = ref.read(driverKycDocumentPickerProvider);
    try {
      final document = await picker.pick(source);
      if (document == null || !mounted) return;
      await ref
          .read(driverVehicleFormProvider.notifier)
          .setDocument(type, document);
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'Impossible d\'accéder à la caméra.');
      }
    }
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

  void _showVehicleDocumentsUpdateSheet(int kycId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverVehicleUpdateSheet(kycId: kycId),
    );
  }

  void _syncControllers(DriverVehicleFormState state) {
    _syncController(_brandController, state.brand);
    _syncController(_modelController, state.model);
    _syncController(_yearController, state.year);
    _syncController(_colorController, state.color);
    _syncController(_licensePlateController, state.licensePlate);
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}
