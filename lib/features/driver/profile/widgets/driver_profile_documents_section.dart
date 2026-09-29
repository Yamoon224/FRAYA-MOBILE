library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../domain/models/driver_kyc_document_type.dart';
import '../models/driver_profile_view_data.dart';

class DriverProfileDocumentsSection extends StatelessWidget {
  const DriverProfileDocumentsSection({
    super.key,
    required this.documents,
    this.onDocumentTap,
    this.onUpdateTap,
  });

  final List<DriverProfileDocumentViewData> documents;
  final ValueChanged<DriverProfileDocumentViewData>? onDocumentTap;
  final VoidCallback? onUpdateTap;

  @override
  Widget build(BuildContext context) {
    final personalDocuments = documents
        .where((doc) => doc.section == DriverKycDocumentSection.driver)
        .toList(growable: false);
    final vehicleDocuments = documents
        .where((doc) => doc.section == DriverKycDocumentSection.vehicle)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Documents', style: AppTextStyles.h1),
        const SizedBox(height: 10),
        _DocumentGroup(
          title: 'Documents personnels',
          documents: personalDocuments,
          onDocumentTap: onDocumentTap,
        ),
        const SizedBox(height: 14),
        _DocumentGroup(
          title: 'Documents véhicule',
          documents: vehicleDocuments,
          onDocumentTap: onDocumentTap,
        ),
        if (onUpdateTap != null) ...[
          const SizedBox(height: 6),
          _UpdateButton(onTap: onUpdateTap!),
        ],
      ],
    );
  }
}

class _DocumentGroup extends StatelessWidget {
  const _DocumentGroup({
    required this.title,
    required this.documents,
    required this.onDocumentTap,
  });

  final String title;
  final List<DriverProfileDocumentViewData> documents;
  final ValueChanged<DriverProfileDocumentViewData>? onDocumentTap;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.colors.greyExtraLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(title, style: AppTextStyles.h3),
        ),
        const SizedBox(height: 10),
        ...documents.map(
          (document) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DocumentTile(
              document: document,
              onTap: onDocumentTap == null
                  ? null
                  : () => onDocumentTap!.call(document),
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document, this.onTap});

  final DriverProfileDocumentViewData document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(document.status);
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: context.colors.greyLight),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: style.iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(document.label, style: AppTextStyles.h2),
                    const SizedBox(height: 2),
                    Text(
                      'Expire le ${document.expiryLabel}',
                      style: AppTextStyles.small.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: style.badgeBackground,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: style.badgeBorder),
                ),
                child: Text(
                  document.statusLabel,
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: style.badgeText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentStyle {
  const _DocumentStyle({
    required this.iconColor,
    required this.badgeBackground,
    required this.badgeBorder,
    required this.badgeText,
  });

  final Color iconColor;
  final Color badgeBackground;
  final Color badgeBorder;
  final Color badgeText;
}

_DocumentStyle _styleFor(DriverProfileDocumentStatus status) {
  return switch (status) {
    DriverProfileDocumentStatus.valid => const _DocumentStyle(
      iconColor: Color(0xFF16A34A),
      badgeBackground: Color(0xFFDDF7E6),
      badgeBorder: Color(0xFFC4ECCF),
      badgeText: Color(0xFF0E8B36),
    ),
    DriverProfileDocumentStatus.expiringSoon => const _DocumentStyle(
      iconColor: Color(0xFFCA8A04),
      badgeBackground: Color(0xFFFDF4C7),
      badgeBorder: Color(0xFFF3E17D),
      badgeText: Color(0xFFB7791F),
    ),
    DriverProfileDocumentStatus.pending => const _DocumentStyle(
      iconColor: Color(0xFF2563EB),
      badgeBackground: Color(0xFFDBEAFE),
      badgeBorder: Color(0xFFBFDBFE),
      badgeText: Color(0xFF1D4ED8),
    ),
    DriverProfileDocumentStatus.rejected => const _DocumentStyle(
      iconColor: Color(0xFFDC2626),
      badgeBackground: Color(0xFFFEE2E2),
      badgeBorder: Color(0xFFFECACA),
      badgeText: Color(0xFFB91C1C),
    ),
    DriverProfileDocumentStatus.missing => const _DocumentStyle(
      iconColor: AppColors.textSecondary,
      badgeBackground: Color(0xFFF3F4F6),
      badgeBorder: Color(0xFFE5E7EB),
      badgeText: Color(0xFF6B7280),
    ),
  };
}

class _UpdateButton extends StatelessWidget {
  const _UpdateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.primaryDark, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.upload_file_outlined,
                color: context.colors.textPrimary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Mettre à jour mes documents',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
