library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/models/driver_kyc_document_file.dart';
import '../error/exceptions.dart';
import 'driver_document_image_compressor.dart';
import 'driver_document_pdf_compressor.dart';

const int driverImageMaxBytes = 2 * 1024 * 1024;
const int driverPdfMaxBytes = 5 * 1024 * 1024;

class DriverDocumentPreparationService {
  DriverDocumentPreparationService({
    DriverDocumentImageCompressor? compressor,
    DriverDocumentPdfCompressor? pdfCompressor,
    Future<Directory> Function()? resolveTemporaryDirectory,
  }) : _compressor = compressor ?? const NativeDriverDocumentImageCompressor(),
       _pdfCompressor =
           pdfCompressor ?? const NativeDriverDocumentPdfCompressor(),
       _resolveTemporaryDirectory =
           resolveTemporaryDirectory ?? getTemporaryDirectory;

  final DriverDocumentImageCompressor _compressor;
  final DriverDocumentPdfCompressor _pdfCompressor;
  final Future<Directory> Function() _resolveTemporaryDirectory;

  Future<DriverKycDocumentFile> prepare(DriverKycDocumentFile document) async {
    final source = File(document.path);
    if (!await source.exists()) {
      throw const DocumentPreparationException(
        message: 'Le document sélectionné est introuvable.',
      );
    }
    if (!DriverKycDocumentFile.isSupported(document.path)) {
      throw const DocumentPreparationException(
        message: 'Formats autorisés : PDF, JPG, JPEG ou PNG.',
      );
    }
    if (document.isPdf) {
      if (await source.length() <= driverPdfMaxBytes) {
        return document;
      }
      return _compressPdf(document);
    }
    if (await source.length() <= driverImageMaxBytes) {
      return document;
    }
    return _compressImage(document);
  }

  Future<void> cleanupTemporary(DriverKycDocumentFile document) async {
    final directory = await _resolveTemporaryDirectory();
    final file = File(document.path);
    if (!_isOwnedTemporary(file, directory) || !await file.exists()) {
      return;
    }
    await file.delete();
  }

  Future<DriverKycDocumentFile> _compressImage(
    DriverKycDocumentFile document,
  ) async {
    final directory = await _resolveTemporaryDirectory();
    for (var index = 0; index < _attempts.length; index++) {
      final output = File(_targetPath(directory, document, index));
      await _deleteIfExists(output);
      final attempt = _attempts[index];
      try {
        await _compressor.compress(
          sourcePath: document.path,
          targetPath: output.path,
          quality: attempt.quality,
          minimumDimension: attempt.minimumDimension,
        );
      } catch (_) {
        await _deleteIfExists(output);
        throw const DocumentPreparationException(
          message: 'Impossible de compresser cette image.',
        );
      }
      if (!await output.exists()) {
        continue;
      }
      final outputSize = await output.length();
      if (outputSize > 0 && outputSize <= driverImageMaxBytes) {
        return DriverKycDocumentFile(
          path: output.path,
          fileName: '${_baseName(document.fileName)}_compressed.jpg',
          mimeType: 'image/jpeg',
          source: document.source,
        );
      }
      await output.delete();
    }
    throw const DocumentPreparationException(
      message:
          'Cette image reste supérieure à 2 Mo après compression. Choisissez une image moins lourde.',
    );
  }

  Future<DriverKycDocumentFile> _compressPdf(
    DriverKycDocumentFile document,
  ) async {
    final directory = await _resolveTemporaryDirectory();
    for (var index = 0; index < _pdfAttempts.length; index++) {
      final output = File(_pdfTargetPath(directory, document, index));
      await _deleteIfExists(output);
      final attempt = _pdfAttempts[index];
      try {
        await _pdfCompressor.compress(
          sourcePath: document.path,
          targetPath: output.path,
          dpi: attempt.dpi,
          quality: attempt.quality,
        );
      } catch (_) {
        await _deleteIfExists(output);
        throw const DocumentPreparationException(
          message:
              'Ce PDF est protégé, corrompu ou illisible. Choisissez un autre document.',
        );
      }
      if (!await output.exists()) {
        continue;
      }
      final outputSize = await output.length();
      if (outputSize > 0 && outputSize <= driverPdfMaxBytes) {
        return DriverKycDocumentFile(
          path: output.path,
          fileName: '${_baseName(document.fileName)}_compressed.pdf',
          mimeType: 'application/pdf',
          source: document.source,
        );
      }
      await output.delete();
    }
    throw const DocumentPreparationException(
      message:
          'Impossible de réduire ce PDF sous 5 Mo. Choisissez un document moins lourd.',
    );
  }

  String _targetPath(
    Directory directory,
    DriverKycDocumentFile document,
    int attempt,
  ) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return '${directory.path}${Platform.pathSeparator}'
        'fraya_upload_${_baseName(document.fileName)}_${stamp}_$attempt.jpg';
  }

  String _pdfTargetPath(
    Directory directory,
    DriverKycDocumentFile document,
    int attempt,
  ) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return '${directory.path}${Platform.pathSeparator}'
        'fraya_upload_${_baseName(document.fileName)}_${stamp}_$attempt.pdf';
  }
}

class _CompressionAttempt {
  const _CompressionAttempt(this.quality, this.minimumDimension);

  final int quality;
  final int minimumDimension;
}

const _attempts = <_CompressionAttempt>[
  _CompressionAttempt(85, 2400),
  _CompressionAttempt(75, 2048),
  _CompressionAttempt(65, 1800),
  _CompressionAttempt(60, 1600),
];

class _PdfCompressionAttempt {
  const _PdfCompressionAttempt(this.dpi, this.quality);

  final int dpi;
  final int quality;
}

const _pdfAttempts = <_PdfCompressionAttempt>[
  _PdfCompressionAttempt(144, 75),
  _PdfCompressionAttempt(120, 65),
  _PdfCompressionAttempt(96, 55),
];

String _baseName(String fileName) {
  final name = fileName.trim().isEmpty ? 'document' : fileName.trim();
  final dotIndex = name.lastIndexOf('.');
  final withoutExtension = dotIndex > 0 ? name.substring(0, dotIndex) : name;
  return withoutExtension.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}

bool _isOwnedTemporary(File file, Directory directory) {
  final normalizedFile = file.absolute.path.replaceAll('\\', '/');
  final normalizedDirectory = directory.absolute.path.replaceAll('\\', '/');
  return normalizedFile.startsWith('$normalizedDirectory/') &&
      file.uri.pathSegments.last.startsWith('fraya_upload_');
}

Future<void> _deleteIfExists(File file) async {
  if (await file.exists()) {
    await file.delete();
  }
}
