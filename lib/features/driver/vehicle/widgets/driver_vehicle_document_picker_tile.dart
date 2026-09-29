library;

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../domain/models/driver_kyc_document_file.dart';
import '../../../../domain/models/driver_vehicle_document_type.dart';

class DriverVehicleDocumentPickerTile extends StatelessWidget {
  const DriverVehicleDocumentPickerTile({
    super.key,
    required this.type,
    required this.document,
    required this.enabled,
    required this.onSelect,
    required this.onRemove,
    this.isProcessing = false,
  });

  final DriverVehicleDocumentType type;
  final DriverKycDocumentFile? document;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final child = isProcessing
        ? const _ProcessingTile()
        : document == null
        ? _EmptyTile(type: type)
        : _FilledTile(type: type, document: document!, enabled: enabled);

    return Column(
      children: [
        InkWell(
          onTap: enabled ? onSelect : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: document == null
              ? DottedBorder(
                  options: const RoundedRectDottedBorderOptions(
                    color: AppColors.border,
                    radius: Radius.circular(AppTheme.radiusLg),
                    dashPattern: [6, 4],
                    padding: EdgeInsets.zero,
                  ),
                  child: child,
                )
              : child,
        ),
        if (document != null && enabled && !isProcessing) ...[
          const SizedBox(height: AppTheme.spacingSm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRemove,
              child: const Text('Supprimer'),
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spacingSm),
      ],
    );
  }
}

class _ProcessingTile extends StatelessWidget {
  const _ProcessingTile();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 112,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Text('Optimisation du document...'),
          ],
        ),
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile({required this.type});

  final DriverVehicleDocumentType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type.label, style: AppTextStyles.h4),
          const SizedBox(height: 4),
          Text(type.helperText, style: AppTextStyles.small),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              const Icon(Icons.add_circle_outline, color: AppColors.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Text('Ajouter un document', style: AppTextStyles.body),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilledTile extends StatelessWidget {
  const _FilledTile({
    required this.type,
    required this.document,
    required this.enabled,
  });

  final DriverVehicleDocumentType type;
  final DriverKycDocumentFile document;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: context.colors.greyExtraLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: document.isPdf
                ? AppColors.infoBackground
                : AppColors.primaryLight,
            child: Icon(
              document.isPdf
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
              color: document.isPdf
                  ? AppColors.infoText
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.label, style: AppTextStyles.h4),
                const SizedBox(height: 4),
                Text(
                  document.fileName,
                  style: AppTextStyles.small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  document.isPdf ? 'PDF sélectionné' : 'Image sélectionnée',
                  style: AppTextStyles.xs,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            enabled ? 'Remplacer' : 'Verrouillé',
            style: AppTextStyles.small.copyWith(color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}
