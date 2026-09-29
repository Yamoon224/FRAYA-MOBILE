library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/widgets/app_snack_bar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../domain/models/driver_kyc_document_file.dart';
import '../../../../domain/models/driver_kyc_document_type.dart';
import '../models/driver_profile_view_data.dart';
import '../providers/driver_kyc_update_notifier.dart';
import '../../kyc/providers/driver_kyc_dependencies.dart';
import '../../kyc/widgets/driver_document_source_sheet.dart';
import 'driver_document_photo_viewer.dart';

class DriverKycUpdateDocumentTile extends ConsumerWidget {
  const DriverKycUpdateDocumentTile({
    super.key,
    required this.type,
    required this.enabled,
    this.canReplace = true,
    this.existingUrl,
  });

  final DriverKycDocumentType type;
  final bool enabled;
  final bool canReplace;
  final String? existingUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      driverKycUpdateProvider.select((s) => s.selectedDocuments[type]),
    );
    final isProcessing = ref.watch(
      driverKycUpdateProvider.select(
        (s) => s.processingDocuments.contains(type),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: selected != null ? AppColors.primary : context.colors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isProcessing)
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  _DocumentIcon(file: selected, existingUrl: existingUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: _DocumentInfo(
                    type: type,
                    file: isProcessing ? null : selected,
                    existingUrl: existingUrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _ActionButton(
                file: selected,
                enabled: enabled && !isProcessing,
                canReplace: canReplace,
                hasExistingUrl: existingUrl != null,
                onSelect: () => _pickDocument(context, ref),
                onRemove: () => ref
                    .read(driverKycUpdateProvider.notifier)
                    .removeDocument(type),
                onConsult: () => _consultDocument(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocument(BuildContext context, WidgetRef ref) async {
    final cameraAvailable =
        ImagePicker().supportsImageSource(ImageSource.camera);

    final source = await DriverDocumentSourceSheet.show(
      context,
      cameraAvailable: cameraAvailable,
    );
    if (source == null) return;

    final picker = ref.read(driverKycDocumentPickerProvider);
    try {
      final file = await picker.pick(source);
      if (file == null) return;
      await ref.read(driverKycUpdateProvider.notifier).setDocument(type, file);
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Impossible d\'accéder à la caméra.');
      }
    }
  }

  void _consultDocument(BuildContext context) {
    final doc = DriverProfileDocumentViewData(
      type: type,
      section: type.section,
      label: type.label,
      expiryLabel: '',
      statusLabel: '',
      status: DriverProfileDocumentStatus.valid,
      documentUrl: existingUrl,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverDocumentPhotoViewer(document: doc),
    );
  }
}

class _DocumentIcon extends StatelessWidget {
  const _DocumentIcon({required this.file, required this.existingUrl});

  final DriverKycDocumentFile? file;
  final String? existingUrl;

  @override
  Widget build(BuildContext context) {
    if (file != null) {
      return CircleAvatar(
        backgroundColor: file!.isPdf
            ? AppColors.infoBackground
            : AppColors.primaryLight,
        child: Icon(
          file!.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
          color: file!.isPdf ? AppColors.infoText : AppColors.textPrimary,
        ),
      );
    }
    if (existingUrl != null) {
      return CircleAvatar(
        backgroundColor: AppColors.successBackground,
        child: const Icon(
          Icons.check_circle_outline_rounded,
          color: AppColors.successText,
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: AppColors.greyExtraLight,
      child: Icon(Icons.upload_file_outlined, color: AppColors.textSecondary),
    );
  }
}

class _DocumentInfo extends StatelessWidget {
  const _DocumentInfo({
    required this.type,
    required this.file,
    required this.existingUrl,
  });

  final DriverKycDocumentType type;
  final DriverKycDocumentFile? file;
  final String? existingUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type.label,
          style: AppTextStyles.h4,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        if (file != null)
          Text(
            file!.fileName,
            style: AppTextStyles.small.copyWith(color: AppColors.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        else if (existingUrl != null)
          Text(
            'Document soumis',
            style: AppTextStyles.small.copyWith(color: AppColors.successText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        else
          Text(
            type.helperText,
            style: AppTextStyles.small,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.file,
    required this.enabled,
    required this.canReplace,
    required this.hasExistingUrl,
    required this.onSelect,
    required this.onRemove,
    required this.onConsult,
  });

  final DriverKycDocumentFile? file;
  final bool enabled;
  final bool canReplace;
  final bool hasExistingUrl;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  final VoidCallback onConsult;

  @override
  Widget build(BuildContext context) {
    if (file != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: enabled && canReplace ? onSelect : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Changer',
              style: AppTextStyles.buttonSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: enabled && canReplace ? onRemove : null,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasExistingUrl) ...[
          IconButton(
            onPressed: enabled ? onConsult : null,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            color: AppColors.primary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Consulter',
          ),
          const SizedBox(width: 4),
        ],
        TextButton(
          onPressed: enabled && canReplace ? onSelect : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            hasExistingUrl ? 'Remplacer' : 'Choisir',
            style: AppTextStyles.buttonSmall.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
