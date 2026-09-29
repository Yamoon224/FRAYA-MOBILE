import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/features/driver/profile/models/driver_profile_view_data.dart';
import 'package:fraya_mobile/features/driver/profile/providers/driver_profile_document_review_provider.dart';

void main() {
  group('applyDriverProfileDocumentReviewOverrides', () {
    test('marks only submitted personal document as pending', () {
      final documents = <DriverProfileDocumentViewData>[
        const DriverProfileDocumentViewData(
          type: DriverKycDocumentType.photoFrontPermis,
          section: DriverKycDocumentSection.driver,
          label: 'Permis - recto',
          expiryLabel: '12/2028',
          statusLabel: 'Valide',
          status: DriverProfileDocumentStatus.valid,
          documentUrl: 'https://example.com/license.png',
        ),
        const DriverProfileDocumentViewData(
          type: DriverKycDocumentType.insuranceCertificate,
          section: DriverKycDocumentSection.vehicle,
          label: 'Assurance vehicule',
          expiryLabel: '01/2027',
          statusLabel: 'Valide',
          status: DriverProfileDocumentStatus.valid,
          documentUrl: 'https://example.com/insurance.png',
        ),
      ];

      final updated = applyDriverProfileDocumentReviewOverrides(
        documents: documents,
        overrides: const {
          DriverKycDocumentType.photoFrontPermis:
              DriverProfileDocumentStatus.pending,
        },
      );

      expect(updated[0].label, 'Permis - recto');
      expect(updated[0].status, DriverProfileDocumentStatus.pending);
      expect(updated[0].statusLabel, 'En attente');
      expect(updated[1].label, 'Assurance vehicule');
      expect(updated[1].status, DriverProfileDocumentStatus.valid);
    });

    test('marks submitted vehicle document as pending', () {
      final documents = <DriverProfileDocumentViewData>[
        const DriverProfileDocumentViewData(
          type: DriverKycDocumentType.insuranceCertificate,
          section: DriverKycDocumentSection.vehicle,
          label: 'Assurance vehicule',
          expiryLabel: '01/2027',
          statusLabel: 'Valide',
          status: DriverProfileDocumentStatus.valid,
          documentUrl: 'https://example.com/insurance.png',
        ),
      ];

      final updated = applyDriverProfileDocumentReviewOverrides(
        documents: documents,
        overrides: const {
          DriverKycDocumentType.insuranceCertificate:
              DriverProfileDocumentStatus.pending,
        },
      );

      expect(updated.single.status, DriverProfileDocumentStatus.pending);
      expect(updated.single.statusLabel, 'En attente');
    });
  });

  group('DriverProfileDocumentReviewNotifier', () {
    test('keeps vehicle document review overrides', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(driverProfileDocumentReviewProvider.notifier)
          .markDocuments(const [
            DriverKycDocumentType.insuranceCertificate,
          ], DriverProfileDocumentStatus.pending);

      expect(container.read(driverProfileDocumentReviewProvider), {
        DriverKycDocumentType.insuranceCertificate:
            DriverProfileDocumentStatus.pending,
      });
    });
  });
}
