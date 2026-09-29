library;

import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;

abstract interface class DriverDocumentPdfCompressor {
  Future<void> compress({
    required String sourcePath,
    required String targetPath,
    required int dpi,
    required int quality,
  });
}

class NativeDriverDocumentPdfCompressor implements DriverDocumentPdfCompressor {
  const NativeDriverDocumentPdfCompressor();

  @override
  Future<void> compress({
    required String sourcePath,
    required String targetPath,
    required int dpi,
    required int quality,
  }) async {
    final source = await pdfx.PdfDocument.openFile(sourcePath);
    try {
      final output = pw.Document(compress: true);
      for (var pageNumber = 1; pageNumber <= source.pagesCount; pageNumber++) {
        await _appendPage(output, source, pageNumber, dpi, quality);
      }
      await File(targetPath).writeAsBytes(await output.save(), flush: true);
    } finally {
      await source.close();
    }
  }

  Future<void> _appendPage(
    pw.Document output,
    pdfx.PdfDocument source,
    int pageNumber,
    int dpi,
    int quality,
  ) async {
    final page = await source.getPage(pageNumber);
    try {
      final scale = dpi / PdfPageFormat.inch;
      final rendered = await page.render(
        width: page.width * scale,
        height: page.height * scale,
        format: pdfx.PdfPageImageFormat.jpeg,
        backgroundColor: '#FFFFFF',
        quality: quality,
      );
      if (rendered == null) {
        throw StateError('La page $pageNumber ne peut pas être rendue.');
      }
      _addRenderedPage(output, page.width, page.height, rendered.bytes);
    } finally {
      await page.close();
    }
  }

  void _addRenderedPage(
    pw.Document output,
    double width,
    double height,
    Uint8List imageBytes,
  ) {
    final image = pw.MemoryImage(imageBytes);
    output.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width, height),
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Image(image, fit: pw.BoxFit.fill),
        ),
      ),
    );
  }
}
