import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_document_type.dart';
import 'package:fraya_mobile/features/driver/vehicle/providers/driver_vehicle_form_state.dart';

void main() {
  group('DriverVehicleFormState', () {
    test('canSubmit is false when vehicle fields are incomplete', () {
      final state = DriverVehicleFormState(
        brand: 'Toyota',
        documents: {
          DriverVehicleDocumentType.insuranceCertificate:
              const DriverKycDocumentFile(
                path: '/tmp/insurance.pdf',
                fileName: 'insurance.pdf',
                mimeType: 'application/pdf',
                source: DriverKycDocumentSource.pdfFile,
              ),
        },
      );

      expect(state.canSubmit, isFalse);
    });

    test('canSubmit is true when all fields and documents are present', () {
      final documents = <DriverVehicleDocumentType, DriverKycDocumentFile>{};
      for (final type in DriverVehicleDocumentType.values) {
        documents[type] = const DriverKycDocumentFile(
          path: '/tmp/document.pdf',
          fileName: 'document.pdf',
          mimeType: 'application/pdf',
          source: DriverKycDocumentSource.pdfFile,
        );
      }

      final state = DriverVehicleFormState(
        brand: 'Toyota',
        model: 'Corolla',
        year: '2022',
        color: 'Rouge',
        licensePlate: 'AB-123-CD',
        selectedRange: 'MAGIC',
        documents: documents,
      );

      expect(state.canSubmit, isTrue);
    });

    test('canSubmit is false when one vehicle photo is missing', () {
      final documents = <DriverVehicleDocumentType, DriverKycDocumentFile>{
        for (final type in DriverVehicleDocumentType.values)
          if (type != DriverVehicleDocumentType.photoInteriorVehicle)
            type: const DriverKycDocumentFile(
              path: '/tmp/document.pdf',
              fileName: 'document.pdf',
              mimeType: 'application/pdf',
              source: DriverKycDocumentSource.pdfFile,
            ),
      };

      final state = DriverVehicleFormState(
        brand: 'Toyota',
        model: 'Corolla',
        year: '2022',
        color: 'Rouge',
        licensePlate: 'AB-123-CD',
        selectedRange: 'MAGIC',
        documents: documents,
      );

      expect(state.canSubmit, isFalse);
    });
  });
}
