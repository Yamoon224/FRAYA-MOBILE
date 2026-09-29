import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_onboarding_draft.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_document_type.dart';

void main() {
  group('DriverOnboardingDraft', () {
    test('serializes and restores kyc and vehicle documents', () {
      final draft = DriverOnboardingDraft(
        kycDocuments: {
          DriverKycDocumentType.photoFrontPermis: _image(
            '/persisted/front.png',
            'front.png',
          ),
        },
        vehicleDocuments: {
          DriverVehicleDocumentType.vehicleRegistration: _pdf(
            '/persisted/registration.pdf',
            'registration.pdf',
          ),
          for (final type in _newVehiclePhotoTypes)
            type: _image(
              '/persisted/${type.backendField}.png',
              '${type.backendField}.png',
            ),
        },
        brand: 'Toyota',
        model: 'Corolla',
        year: '2022',
        color: 'Rouge',
        licensePlate: 'AB-123-CD',
        range: 'MAGIC',
        updatedAt: DateTime.parse('2025-01-10T12:00:00.000Z'),
      );

      final restored = DriverOnboardingDraft.fromMap(draft.toMap());

      expect(restored.brand, 'Toyota');
      expect(restored.kycDocuments.keys, [
        DriverKycDocumentType.photoFrontPermis,
      ]);
      expect(
        restored.vehicleDocuments.keys,
        containsAll([
          DriverVehicleDocumentType.vehicleRegistration,
          ..._newVehiclePhotoTypes,
        ]),
      );
      expect(
        restored
            .vehicleDocuments[DriverVehicleDocumentType.vehicleRegistration]
            ?.mimeType,
        'application/pdf',
      );
    });
  });
}

const _newVehiclePhotoTypes = [
  DriverVehicleDocumentType.photoRearVehicle,
  DriverVehicleDocumentType.photoLeftVehicle,
  DriverVehicleDocumentType.photoRightVehicle,
  DriverVehicleDocumentType.photoInteriorVehicle,
];

DriverKycDocumentFile _image(String path, String fileName) {
  return DriverKycDocumentFile.fromPath(
    path: path,
    fileName: fileName,
    source: DriverKycDocumentSource.galleryImage,
  )!;
}

DriverKycDocumentFile _pdf(String path, String fileName) {
  return DriverKycDocumentFile.fromPath(
    path: path,
    fileName: fileName,
    source: DriverKycDocumentSource.pdfFile,
  )!;
}
