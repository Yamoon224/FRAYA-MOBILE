library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../domain/models/driver_kyc_document_file.dart';

class DriverDocumentSourceSheet extends StatelessWidget {
  const DriverDocumentSourceSheet({super.key, required this.cameraAvailable});

  final bool cameraAvailable;

  static Future<DriverKycDocumentSource?> show(
    BuildContext context, {
    required bool cameraAvailable,
  }) {
    return showModalBottomSheet<DriverKycDocumentSource>(
      context: context,
      showDragHandle: true,
      builder: (_) =>
          DriverDocumentSourceSheet(cameraAvailable: cameraAvailable),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajouter un document', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text(
              'Choisissez la source du document à envoyer.',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 16),
            if (cameraAvailable)
              _ActionTile(
                icon: Icons.camera_alt_outlined,
                title: 'Prendre une photo',
                subtitle: 'Utiliser la camera',
                onTap: () =>
                    Navigator.of(context).pop(DriverKycDocumentSource.camera),
              ),
            _ActionTile(
              icon: Icons.photo_library_outlined,
              title: 'Choisir une image',
              subtitle: 'Importer depuis la galerie',
              onTap: () => Navigator.of(
                context,
              ).pop(DriverKycDocumentSource.galleryImage),
            ),
            _ActionTile(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Choisir un PDF',
              subtitle: 'Importer un fichier PDF',
              onTap: () =>
                  Navigator.of(context).pop(DriverKycDocumentSource.pdfFile),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: Icon(icon, color: context.colors.textPrimary),
      ),
      title: Text(title, style: AppTextStyles.h4),
      subtitle: Text(subtitle, style: AppTextStyles.small),
      onTap: onTap,
    );
  }
}
