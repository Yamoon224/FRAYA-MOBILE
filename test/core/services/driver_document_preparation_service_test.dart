import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/services/driver_document_image_compressor.dart';
import 'package:fraya_mobile/core/services/driver_document_pdf_compressor.dart';
import 'package:fraya_mobile/core/services/driver_document_preparation_service.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';

class _SizedImageCompressor implements DriverDocumentImageCompressor {
  _SizedImageCompressor(this.outputSizes);

  final List<int> outputSizes;
  int calls = 0;

  @override
  Future<void> compress({
    required String sourcePath,
    required String targetPath,
    required int quality,
    required int minimumDimension,
  }) async {
    final index = calls.clamp(0, outputSizes.length - 1);
    calls++;
    await _writeSizedFile(File(targetPath), outputSizes[index]);
  }
}

class _SizedPdfCompressor implements DriverDocumentPdfCompressor {
  _SizedPdfCompressor(this.outputSizes, {this.error});

  final List<int> outputSizes;
  final Object? error;
  final List<(int, int)> attempts = [];

  @override
  Future<void> compress({
    required String sourcePath,
    required String targetPath,
    required int dpi,
    required int quality,
  }) async {
    if (error != null) throw error!;
    final index = attempts.length.clamp(0, outputSizes.length - 1);
    attempts.add((dpi, quality));
    await _writeSizedFile(File(targetPath), outputSizes[index]);
  }
}

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('fraya_document_test_');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('keeps an image already below 2 MB unchanged', () async {
    final source = await _createSizedFile(directory, 'small.jpg', 1024);
    final imageCompressor = _SizedImageCompressor([100]);
    final document = _document(source, 'small.jpg');

    final result = await _service(directory, imageCompressor).prepare(document);

    expect(result, same(document));
    expect(imageCompressor.calls, 0);
  });

  test('keeps a PDF between 2 MB and 5 MB unchanged', () async {
    final source = await _createSizedFile(
      directory,
      'medium.pdf',
      driverImageMaxBytes + 1,
    );
    final document = _document(source, 'medium.pdf');

    final result = await _service(
      directory,
      _SizedImageCompressor([100]),
    ).prepare(document);

    expect(result, same(document));
  });

  test('keeps a PDF exactly equal to 5 MB unchanged', () async {
    final source = await _createSizedFile(
      directory,
      'limit.pdf',
      driverPdfMaxBytes,
    );
    final document = _document(source, 'limit.pdf');

    final result = await _service(
      directory,
      _SizedImageCompressor([100]),
    ).prepare(document);

    expect(result, same(document));
  });

  test('compresses a PDF above 5 MB and returns PDF metadata', () async {
    final source = await _largePdf(directory, 'identity.pdf');
    final pdfCompressor = _SizedPdfCompressor([driverPdfMaxBytes - 100]);
    final service = _service(
      directory,
      _SizedImageCompressor([100]),
      pdfCompressor: pdfCompressor,
    );

    final result = await service.prepare(_document(source, 'identity.pdf'));

    expect(pdfCompressor.attempts, [(144, 75)]);
    expect(result.fileName, 'identity_compressed.pdf');
    expect(result.mimeType, 'application/pdf');
    expect(
      await File(result.path).length(),
      lessThanOrEqualTo(5 * 1024 * 1024),
    );
    await service.cleanupTemporary(result);
    expect(await File(result.path).exists(), isFalse);
  });

  test('uses lower PDF quality until the target is reached', () async {
    final source = await _largePdf(directory, 'scan.pdf');
    final pdfCompressor = _SizedPdfCompressor([
      driverPdfMaxBytes + 100,
      driverPdfMaxBytes - 100,
    ]);

    await _service(
      directory,
      _SizedImageCompressor([100]),
      pdfCompressor: pdfCompressor,
    ).prepare(_document(source, 'scan.pdf'));

    expect(pdfCompressor.attempts, [(144, 75), (120, 65)]);
  });

  test('rejects a PDF when all attempts remain too large', () async {
    final source = await _largePdf(directory, 'huge.pdf');
    final pdfCompressor = _SizedPdfCompressor(
      List.filled(3, driverPdfMaxBytes + 1),
    );
    final service = _service(
      directory,
      _SizedImageCompressor([100]),
      pdfCompressor: pdfCompressor,
    );

    await expectLater(
      service.prepare(_document(source, 'huge.pdf')),
      throwsA(
        isA<DocumentPreparationException>().having(
          (error) => error.message,
          'message',
          contains('Impossible de réduire ce PDF sous 5 Mo'),
        ),
      ),
    );
    expect(pdfCompressor.attempts, [(144, 75), (120, 65), (96, 55)]);
    _expectNoTemporaryFiles(directory);
  });

  test('reports a protected or unreadable PDF', () async {
    final source = await _largePdf(directory, 'protected.pdf');
    final service = _service(
      directory,
      _SizedImageCompressor([100]),
      pdfCompressor: _SizedPdfCompressor([100], error: StateError('protected')),
    );

    await expectLater(
      service.prepare(_document(source, 'protected.pdf')),
      throwsA(
        isA<DocumentPreparationException>().having(
          (error) => error.message,
          'message',
          contains('protégé, corrompu ou illisible'),
        ),
      ),
    );
  });

  test('uses adaptive attempts and returns a JPEG below 2 MB', () async {
    final source = await _largeImage(directory, 'identity.png');
    final compressor = _SizedImageCompressor([
      driverImageMaxBytes + 100,
      driverImageMaxBytes - 100,
    ]);

    final result = await _service(
      directory,
      compressor,
    ).prepare(_document(source, 'identity.png'));

    expect(compressor.calls, 2);
    expect(result.mimeType, 'image/jpeg');
    expect(result.fileName, 'identity_compressed.jpg');
    expect(
      await File(result.path).length(),
      lessThanOrEqualTo(2 * 1024 * 1024),
    );
  });

  test('rejects an image when every attempt remains too large', () async {
    final source = await _largeImage(directory, 'large.png');
    final compressor = _SizedImageCompressor(
      List.filled(4, driverImageMaxBytes + 1),
    );
    final service = _service(directory, compressor);

    await expectLater(
      service.prepare(_document(source, 'large.png')),
      throwsA(isA<DocumentPreparationException>()),
    );
    expect(compressor.calls, 4);
    _expectNoTemporaryFiles(directory);
  });

  test('rejects a missing source file', () async {
    final missing = File('${directory.path}${Platform.pathSeparator}none.jpg');

    await expectLater(
      _service(
        directory,
        _SizedImageCompressor([100]),
      ).prepare(_document(missing, 'none.jpg')),
      throwsA(isA<DocumentPreparationException>()),
    );
  });
}

DriverDocumentPreparationService _service(
  Directory directory,
  DriverDocumentImageCompressor imageCompressor, {
  DriverDocumentPdfCompressor? pdfCompressor,
}) {
  return DriverDocumentPreparationService(
    compressor: imageCompressor,
    pdfCompressor: pdfCompressor ?? _SizedPdfCompressor([100]),
    resolveTemporaryDirectory: () async => directory,
  );
}

Future<File> _largePdf(Directory directory, String name) {
  return _createSizedFile(directory, name, driverPdfMaxBytes + 1);
}

Future<File> _largeImage(Directory directory, String name) {
  return _createSizedFile(directory, name, driverImageMaxBytes + 1);
}

Future<File> _createSizedFile(
  Directory directory,
  String name,
  int size,
) async {
  final file = File('${directory.path}${Platform.pathSeparator}$name');
  await _writeSizedFile(file, size);
  return file;
}

Future<void> _writeSizedFile(File file, int size) async {
  final handle = await file.open(mode: FileMode.write);
  await handle.truncate(size);
  await handle.close();
}

DriverKycDocumentFile _document(File file, String name) {
  return DriverKycDocumentFile.fromPath(
    path: file.path,
    fileName: name,
    source: name.endsWith('.pdf')
        ? DriverKycDocumentSource.pdfFile
        : DriverKycDocumentSource.galleryImage,
  )!;
}

void _expectNoTemporaryFiles(Directory directory) {
  expect(
    directory.listSync().whereType<File>().where(
      (file) => file.path.contains('fraya_upload_'),
    ),
    isEmpty,
  );
}
