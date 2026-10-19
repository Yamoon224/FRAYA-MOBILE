library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/driver_kyc_document_file.dart';
import '../../../../domain/models/driver_kyc_document_type.dart';
import '../../../../domain/models/driver_vehicle_document_type.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../../../../shared/widgets/settings/logout_confirmation_dialog.dart';
import '../../auth/providers/driver_admin_status_gate.dart';
import '../../auth/providers/driver_auth_provider.dart';
import '../../kyc/providers/driver_kyc_dependencies.dart';
import '../../kyc/providers/driver_kyc_provider.dart';
import '../../kyc/widgets/driver_document_picker_tile.dart';
import '../../kyc/widgets/driver_document_source_sheet.dart';
import '../../kyc/widgets/driver_kyc_deadline_notice.dart';
import '../providers/driver_registration_sender.dart';
import '../providers/driver_vehicle_form_provider.dart';
import '../providers/driver_vehicle_form_state.dart';
import '../widgets/driver_vehicle_documents_section.dart';
import '../widgets/driver_vehicle_info_section.dart';
import '../widgets/single_open_accordion.dart';

/// Inscription chauffeur sur une seule page : documents du chauffeur, informations du véhicule et
/// documents du véhicule, en trois accordéons (un seul ouvert à la fois, le premier par défaut)
/// et un seul bouton d'envoi. Les écrans de correction après un refus restent ceux d'avant.
class DriverRegistrationScreen extends ConsumerStatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  ConsumerState<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState
    extends ConsumerState<DriverRegistrationScreen> {
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _licensePlateController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Future<void> _goBack() async {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final confirmed = await showLogoutConfirmationDialog(context);
    if (!confirmed || !mounted) return;
    await ref.read(driverAuthProvider.notifier).logout();
  }

  Future<void> _send(bool needsKycSubmission) async {
    setState(() => _isSending = true);
    try {
      await sendDriverRegistration(
        needsKycSubmission: needsKycSubmission,
        submitKyc: () async {
          await ref.read(driverKycFormProvider.notifier).submit();
          final kyc = ref.read(driverKycFormProvider);
          return kyc.errorMessage == null && kyc.lastSubmittedAt != null;
        },
        submitVehicle: ref.read(driverVehicleFormProvider.notifier).submit,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(driverKycFormProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppSnackBar.showError(context, next.errorMessage!);
      }
    });
    ref.listen(driverVehicleFormProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppSnackBar.showError(context, next.errorMessage!);
      }
      if (next.lastSubmittedAt != null &&
          next.lastSubmittedAt != previous?.lastSubmittedAt) {
        AppSnackBar.showSuccess(
          context,
          'Dossier envoyé. Validation admin en cours.',
        );
      }
    });

    final authState = ref.watch(driverAuthProvider);
    final kycForm = ref.watch(driverKycFormProvider);
    final vehicleForm = ref.watch(driverVehicleFormProvider);
    final gate = DriverAdminStatusGate.fromUserData(authState.userData);
    _syncControllers(vehicleForm.brand, vehicleForm.model, vehicleForm.year,
        vehicleForm.color, vehicleForm.licensePlate);

    final needsKyc = gate.needsKycSubmission;
    final busy = _isSending || kycForm.isSubmitting || vehicleForm.isSubmitting;
    final driverDocsComplete = !needsKyc || kycForm.canSubmit;
    final vehicleInfoComplete =
        vehicleForm.brand.trim().isNotEmpty &&
        vehicleForm.model.trim().isNotEmpty &&
        vehicleForm.year.trim().isNotEmpty &&
        vehicleForm.color.trim().isNotEmpty &&
        vehicleForm.licensePlate.trim().isNotEmpty;
    final vehicleDocsComplete = requiredVehicleDocuments.every(
      vehicleForm.documents.containsKey,
    );
    final canSend =
        !busy &&
        driverDocsComplete &&
        vehicleInfoComplete &&
        vehicleDocsComplete &&
        vehicleForm.processingDocuments.isEmpty &&
        kycForm.processingDocuments.isEmpty;
    final missing = <String>[
      if (!driverDocsComplete) 'documents du chauffeur',
      if (!vehicleInfoComplete) 'informations du véhicule',
      if (!vehicleDocsComplete) 'documents du véhicule',
    ];

    return Scaffold(
      backgroundColor: context.colors.background,
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
                      onPressed: _goBack,
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
                  'Inscription chauffeur',
                  style: context.textH1.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Complétez les trois sections puis envoyez votre dossier en une seule fois.',
                  style: context.textBody.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                SingleOpenAccordion(
                  sections: [
                    AccordionSection(
                      id: 'driver-documents',
                      title: 'Documents du chauffeur',
                      subtitle: needsKyc
                          ? 'Permis recto et verso, casier judiciaire (facultatif).'
                          : 'Déjà envoyés.',
                      isComplete: driverDocsComplete,
                      child: needsKyc
                          ? _buildDriverDocuments(kycForm.documents, kycForm.processingDocuments, busy)
                          : Text(
                              'Vos documents de chauffeur ont bien été envoyés.',
                              style: AppTextStyles.small,
                            ),
                    ),
                    AccordionSection(
                      id: 'vehicle-info',
                      title: 'Informations du véhicule',
                      subtitle: 'Marque, modèle, gamme, climatisation.',
                      isComplete: vehicleInfoComplete,
                      child: _buildVehicleInfo(vehicleForm, busy),
                    ),
                    AccordionSection(
                      id: 'vehicle-documents',
                      title: 'Documents du véhicule',
                      subtitle:
                          'Cinq photos, carte grise et visite technique. Assurance facultative.',
                      isComplete: vehicleDocsComplete,
                      child: DriverVehicleDocumentsSection(
                        documents: vehicleForm.documents,
                        processingDocuments: vehicleForm.processingDocuments,
                        enabled: !busy,
                        onSelect: _pickVehicleDocument,
                        onRemove: ref
                            .read(driverVehicleFormProvider.notifier)
                            .removeDocument,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                if (needsKyc) ...[
                  const DriverKycDeadlineNotice(),
                  const SizedBox(height: AppTheme.spacingMd),
                ],
                if (missing.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                    child: Text(
                      'Il reste à compléter : ${missing.join(', ')}.',
                      key: const ValueKey('registration-missing'),
                      style: AppTextStyles.small,
                    ),
                  ),
                FrayaButton(
                  label: 'Envoyer mon dossier',
                  onPressed: canSend ? () => _send(needsKyc) : null,
                  isLoading: busy,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                FrayaButton(
                  label: 'Continuer plus tard',
                  variant: FrayaButtonVariant.ghost,
                  onPressed: busy ? null : _goBack,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverDocuments(
    Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
    Set<DriverKycDocumentType> processing,
    bool busy,
  ) {
    return Column(
      children: [
        for (final type in driverKycDriverDocuments)
          DriverDocumentPickerTile(
            type: type,
            document: documents[type],
            enabled: !busy && !processing.contains(type),
            isProcessing: processing.contains(type),
            isOptional: type == DriverKycDocumentType.photoCasier,
            onSelect: () => _pickDriverDocument(type),
            onRemove: () =>
                ref.read(driverKycFormProvider.notifier).removeDocument(type),
          ),
      ],
    );
  }

  Widget _buildVehicleInfo(DriverVehicleFormState form, bool busy) {
    final notifier = ref.read(driverVehicleFormProvider.notifier);
    return DriverVehicleInfoSection(
      brandController: _brandController,
      modelController: _modelController,
      yearController: _yearController,
      colorController: _colorController,
      licensePlateController: _licensePlateController,
      selectedRange: form.selectedRange,
      selectedSecondaryRange: form.selectedSecondaryRange,
      onSecondaryRangeChanged: notifier.setSecondaryRange,
      airConditioning: form.airConditioning,
      enabled: !busy,
      onBrandChanged: notifier.setBrand,
      onModelChanged: notifier.setModel,
      onYearChanged: notifier.setYear,
      onColorChanged: notifier.setColor,
      onLicensePlateChanged: notifier.setLicensePlate,
      onRangeChanged: notifier.setRange,
      onAirConditioningChanged: notifier.setAirConditioning,
    );
  }

  Future<void> _pickDriverDocument(DriverKycDocumentType type) async {
    final document = await _pickFile();
    if (document == null || !mounted) return;
    await ref.read(driverKycFormProvider.notifier).setDocument(type, document);
  }

  Future<void> _pickVehicleDocument(DriverVehicleDocumentType type) async {
    final document = await _pickFile();
    if (document == null || !mounted) return;
    await ref
        .read(driverVehicleFormProvider.notifier)
        .setDocument(type, document);
  }

  Future<DriverKycDocumentFile?> _pickFile() async {
    final cameraAvailable = ImagePicker().supportsImageSource(
      ImageSource.camera,
    );
    if (!mounted) return null;
    final source = await DriverDocumentSourceSheet.show(
      context,
      cameraAvailable: cameraAvailable,
    );
    if (source == null || !mounted) return null;
    try {
      return await ref.read(driverKycDocumentPickerProvider).pick(source);
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'Impossible d\'accéder à la caméra.');
      }
      return null;
    }
  }

  void _syncControllers(
    String brand,
    String model,
    String year,
    String color,
    String licensePlate,
  ) {
    _syncController(_brandController, brand);
    _syncController(_modelController, model);
    _syncController(_yearController, year);
    _syncController(_colorController, color);
    _syncController(_licensePlateController, licensePlate);
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}
