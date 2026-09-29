library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/extensions.dart';
import '../models/driver_profile_view_data.dart';

class DriverDocumentPhotoViewer extends StatelessWidget {
  const DriverDocumentPhotoViewer({super.key, required this.document});

  final DriverProfileDocumentViewData document;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: ctx.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHandle(ctx),
            _buildHeader(ctx),
            Expanded(child: _buildBody(ctx)),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.greyLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(document.label, style: AppTextStyles.h1)),
          IconButton(
            icon: Icon(Icons.close_rounded, color: context.colors.textSecondary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final url = document.documentUrl;
    if (url == null) return _buildUnavailable(context);

    final isPdf = url.toLowerCase().endsWith('.pdf');
    if (isPdf) return _buildPdfPlaceholder(context);

    return _buildImageViewer(url, context);
  }

  Widget _buildImageViewer(String url, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, _) => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            errorWidget: (_, _, _) => _buildError(context),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            size: 64,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            'Fichier PDF',
            style: AppTextStyles.h1.copyWith(color: context.colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'La prévisualisation PDF\nn\'est pas disponible.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            size: 64,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            'Impossible de charger le document',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailable(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            size: 64,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun document disponible',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
