import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/features/driver/profile/models/driver_profile_view_data.dart';
import 'package:fraya_mobile/features/driver/profile/providers/driver_profile_view_data_resolver.dart';

void main() {
  group('DriverProfileViewDataResolver', () {
    test('formats vehicle range label from backend range', () {
      final viewData = DriverProfileViewDataResolver.fromUserData({
        'vehicles': [
          {'brand': 'Toyota', 'model': 'Corolla', 'range': 'ELITE'},
        ],
      });

      expect(viewData.vehicle?.rangeLabel, contains('lite'));
    });

    test('maps documented KYC documents into personal and vehicle groups', () {
      final viewData = DriverProfileViewDataResolver.fromUserData({
        'kycs': [
          {
            'status': 'VALIDATED',
            'photoFrontPermis': 'front.jpg',
            'photoBackPermis': 'back.jpg',
            'photoSelfPermis': 'selfie.jpg',
            'photoCasier': 'casier.jpg',
            'photoFrontVehicle': 'vehicle-front.jpg',
            'vehicleRegistration': 'registration.jpg',
            'insuranceCertificate': 'insurance.jpg',
            'technicalInspection': 'inspection.jpg',
            'identityCard': 'identity.jpg',
          },
        ],
      });

      expect(viewData.documents.map((doc) => doc.type), [
        DriverKycDocumentType.photoFrontPermis,
        DriverKycDocumentType.photoBackPermis,
        DriverKycDocumentType.photoSelfPermis,
        DriverKycDocumentType.photoCasier,
        DriverKycDocumentType.photoFrontVehicle,
        DriverKycDocumentType.vehicleRegistration,
        DriverKycDocumentType.insuranceCertificate,
        DriverKycDocumentType.technicalInspection,
      ]);
      expect(
        viewData.documents
            .where((doc) => doc.section == DriverKycDocumentSection.driver)
            .length,
        4,
      );
      expect(
        viewData.documents
            .where((doc) => doc.section == DriverKycDocumentSection.vehicle)
            .length,
        4,
      );
      expect(
        viewData.documents.any((doc) => doc.label.contains('ident')),
        isFalse,
      );
      expect(
        viewData.documents
            .where((doc) => doc.status == DriverProfileDocumentStatus.valid)
            .length,
        8,
      );
    });
  });
}
