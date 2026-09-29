import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import 'settings/legal_content.dart';

Future<void> showLegalPdfDialog(
  BuildContext context, {
  required String title,
  required Uri uri,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _LegalPdfDialog(title: title, uri: uri),
  );
}

Future<void> showLegalTextDialog(
  BuildContext context, {
  required String title,
  required List<LegalSection> sections,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _LegalTextDialog(title: title, sections: sections),
  );
}

class _LegalPdfDialog extends StatefulWidget {
  const _LegalPdfDialog({required this.title, required this.uri});

  final String title;
  final Uri uri;

  @override
  State<_LegalPdfDialog> createState() => _LegalPdfDialogState();
}

class _LegalPdfDialogState extends State<_LegalPdfDialog> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openData(_loadPdfBytes()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Uint8List> _loadPdfBytes() async {
    final response = await Dio().getUri<List<int>>(
      widget.uri,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('Document indisponible.');
    }
    return Uint8List.fromList(data);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colors.surface,
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: Column(
          children: [
            _LegalDialogHeader(title: widget.title),
            Expanded(
              child: PdfViewPinch(
                controller: _controller,
                builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                  options: const DefaultBuilderOptions(),
                  documentLoaderBuilder: (_) => const _LegalLoader(),
                  pageLoaderBuilder: (_) => const _LegalLoader(),
                  errorBuilder: (_, error) => _LegalError(
                    message:
                        'Impossible de charger ce document. Vérifiez votre connexion puis réessayez.',
                  ),
                ),
              ),
            ),
            _LegalPdfFooter(controller: _controller),
          ],
        ),
      ),
    );
  }
}

class _LegalTextDialog extends StatelessWidget {
  const _LegalTextDialog({required this.title, required this.sections});

  final String title;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colors.surface,
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          children: [
            _LegalDialogHeader(title: title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final section in sections) ...[
                      Text(
                        section.title,
                        style: AppTextStyles.body.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        section.body,
                        style: AppTextStyles.small.copyWith(
                          color: context.colors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalDialogHeader extends StatelessWidget {
  const _LegalDialogHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            color: context.colors.textSecondary,
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }
}

class _LegalPdfFooter extends StatelessWidget {
  const _LegalPdfFooter({required this.controller});

  final PdfControllerPinch controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => controller.previousPage(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
            ),
            icon: const Icon(Icons.chevron_left),
            color: context.colors.textPrimary,
            tooltip: 'Page précédente',
          ),
          PdfPageNumber(
            controller: controller,
            builder: (_, _, page, pagesCount) => Text(
              '$page/${pagesCount ?? 0}',
              style: AppTextStyles.small.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => controller.nextPage(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
            ),
            icon: const Icon(Icons.chevron_right),
            color: context.colors.textPrimary,
            tooltip: 'Page suivante',
          ),
        ],
      ),
    );
  }
}

class _LegalLoader extends StatelessWidget {
  const _LegalLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryDark),
    );
  }
}

class _LegalError extends StatelessWidget {
  const _LegalError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
        ),
      ),
    );
  }
}
