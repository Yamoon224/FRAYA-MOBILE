import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';

void main() {
  group('DriverKycDocumentFile', () {
    test('creates pdf document file with resolved mime type', () {
      final file = DriverKycDocumentFile.fromPath(
        path: '/tmp/permis.pdf',
        fileName: 'permis.pdf',
        source: DriverKycDocumentSource.pdfFile,
      );

      expect(file, isNotNull);
      expect(file?.mimeType, 'application/pdf');
      expect(file?.isPdf, isTrue);
    });

    test('rejects unsupported extension', () {
      final file = DriverKycDocumentFile.fromPath(
        path: '/tmp/permis.docx',
        fileName: 'permis.docx',
        source: DriverKycDocumentSource.pdfFile,
      );

      expect(file, isNull);
    });
  });
}
