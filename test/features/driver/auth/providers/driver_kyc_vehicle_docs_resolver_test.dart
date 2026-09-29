import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_kyc_vehicle_docs_resolver.dart';

void main() {
  group('DriverKycVehicleDocsResolver', () {
    test('does not require vehicle docs when no KYC record is available', () {
      final result = DriverKycVehicleDocsResolver.resolve(const {
        'driverId': 14,
        'kycStatus': 'APPROVED',
        'vehicleStatus': 'APPROVED',
      });

      expect(result.hasKycRecord, isFalse);
      expect(result.needsVehicleCompletion, isFalse);
      expect(result.hasAllVehicleDocuments, isFalse);
    });

    test('reports missing vehicle documents on the latest KYC record', () {
      final result = DriverKycVehicleDocsResolver.resolve(const {
        'driverId': 14,
        'kycs': [
          {
            'id': 1,
            'updatedAt': '2026-06-28T10:00:00.000Z',
            'insuranceCertificate': 'insurance.pdf',
          },
          {
            'id': 2,
            'updatedAt': '2026-06-30T10:00:00.000Z',
            'photoFrontVehicle': 'front.jpg',
          },
        ],
      });

      expect(result.hasKycRecord, isTrue);
      expect(result.needsVehicleCompletion, isTrue);
      expect(result.missingDocuments, {
        DriverKycDocumentType.insuranceCertificate,
        DriverKycDocumentType.technicalInspection,
        DriverKycDocumentType.vehicleRegistration,
      });
    });

    test(
      'accepts a KYC record only when all vehicle documents are present',
      () {
        final result = DriverKycVehicleDocsResolver.resolve(const {
          'lastKyc': {
            'insuranceCertificate': 'insurance.pdf',
            'technicalInspection': 'inspection.pdf',
            'vehicleRegistration': 'registration.pdf',
            'photoFrontVehicle': 'front.jpg',
          },
        });

        expect(result.hasAllVehicleDocuments, isTrue);
        expect(result.needsVehicleCompletion, isFalse);
        expect(
          DriverKycVehicleDocsResolver.hasVehicleKycDocuments(const {
            'lastKyc': {
              'insuranceCertificate': 'insurance.pdf',
              'technicalInspection': 'inspection.pdf',
              'vehicleRegistration': 'registration.pdf',
              'photoFrontVehicle': 'front.jpg',
            },
          }),
          isTrue,
        );
      },
    );
  });
}
