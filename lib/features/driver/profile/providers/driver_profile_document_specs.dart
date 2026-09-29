library;

import '../../../../domain/models/driver_kyc_document_type.dart';

class DriverProfileDocumentSpec {
  const DriverProfileDocumentSpec({
    required this.type,
    required this.label,
    required this.urlKeys,
    required this.expiryKeys,
    required this.statusKeys,
  });

  final DriverKycDocumentType type;
  final String label;
  final List<String> urlKeys;
  final List<String> expiryKeys;
  final List<String> statusKeys;
}

const List<DriverProfileDocumentSpec> driverProfileDocumentSpecs =
    <DriverProfileDocumentSpec>[
      DriverProfileDocumentSpec(
        type: DriverKycDocumentType.photoFrontPermis,
        label: 'Permis - recto',
        urlKeys: <String>[
          'photoFrontPermis',
          'drivingLicense',
          'drivingLicenseUrl',
        ],
        expiryKeys: <String>[
          'permisExpiresAt',
          'drivingLicenseExpiresAt',
          'drivingLicenseExpiry',
        ],
        statusKeys: <String>['permisStatus', 'drivingLicenseStatus'],
      ),
      DriverProfileDocumentSpec(
        type: DriverKycDocumentType.photoBackPermis,
        label: 'Permis - verso',
        urlKeys: <String>['photoBackPermis'],
        expiryKeys: <String>['permisExpiresAt', 'drivingLicenseExpiresAt'],
        statusKeys: <String>['permisStatus', 'drivingLicenseStatus'],
      ),
      DriverProfileDocumentSpec(
        type: DriverKycDocumentType.photoSelfPermis,
        label: 'Selfie avec permis',
        urlKeys: <String>['photoSelfPermis'],
        expiryKeys: <String>['permisExpiresAt', 'drivingLicenseExpiresAt'],
        statusKeys: <String>['permisStatus', 'drivingLicenseStatus'],
      ),
      DriverProfileDocumentSpec(
        type: DriverKycDocumentType.photoCasier,
        label: 'Casier judiciaire',
        urlKeys: <String>['photoCasier', 'criminalRecord', 'criminalRecordUrl'],
        expiryKeys: <String>['criminalRecordExpiresAt', 'casierExpiresAt'],
        statusKeys: <String>['criminalRecordStatus', 'casierStatus'],
      ),
      DriverProfileDocumentSpec(
        type: DriverKycDocumentType.photoFrontVehicle,
        label: 'Photo avant du véhicule',
        urlKeys: <String>['photoFrontVehicle'],
        expiryKeys: <String>['photoFrontVehicleExpiresAt'],
        statusKeys: <String>['photoFrontVehicleStatus'],
      ),
      DriverProfileDocumentSpec(
        type: DriverKycDocumentType.vehicleRegistration,
        label: 'Carte grise',
        urlKeys: <String>[
          'vehicleRegistration',
          'registrationCard',
          'registrationCardUrl',
        ],
        expiryKeys: <String>[
          'vehicleRegistrationExpiresAt',
          'registrationExpiresAt',
        ],
        statusKeys: <String>['vehicleRegistrationStatus', 'registrationStatus'],
      ),
      DriverProfileDocumentSpec(
        type: DriverKycDocumentType.insuranceCertificate,
        label: 'Assurance véhicule',
        urlKeys: <String>['insuranceCertificate', 'insurance', 'insuranceUrl'],
        expiryKeys: <String>['insuranceExpiresAt', 'insuranceExpiry'],
        statusKeys: <String>['insuranceStatus'],
      ),
      DriverProfileDocumentSpec(
        type: DriverKycDocumentType.technicalInspection,
        label: 'Visite technique',
        urlKeys: <String>[
          'technicalInspection',
          'technicalVisit',
          'technicalVisitUrl',
        ],
        expiryKeys: <String>[
          'technicalInspectionExpiresAt',
          'technicalVisitExpiresAt',
        ],
        statusKeys: <String>[
          'technicalInspectionStatus',
          'technicalVisitStatus',
        ],
      ),
    ];
