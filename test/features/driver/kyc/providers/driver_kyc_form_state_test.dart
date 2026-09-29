import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/features/driver/kyc/providers/driver_kyc_form_state.dart';

void main() {
  group('DriverKycFormState', () {
    test('canSubmit is false when documents are incomplete', () {
      final state = DriverKycFormState(
        documents: {
          DriverKycDocumentType.photoFrontPermis: const DriverKycDocumentFile(
            path: '/tmp/front.jpg',
            fileName: 'front.jpg',
            mimeType: 'image/jpeg',
            source: DriverKycDocumentSource.galleryImage,
          ),
        },
      );

      expect(state.canSubmit, isFalse);
    });

    test('canSubmit is true without the optional criminal record', () {
      final documents = <DriverKycDocumentType, DriverKycDocumentFile>{};
      for (final type in driverKycRequiredDocuments) {
        documents[type] = const DriverKycDocumentFile(
          path: '/tmp/document.jpg',
          fileName: 'document.jpg',
          mimeType: 'image/jpeg',
          source: DriverKycDocumentSource.galleryImage,
        );
      }

      final state = DriverKycFormState(documents: documents);
      expect(state.canSubmit, isTrue);
      expect(
        state.documents,
        isNot(contains(DriverKycDocumentType.photoCasier)),
      );
    });
  });
}
