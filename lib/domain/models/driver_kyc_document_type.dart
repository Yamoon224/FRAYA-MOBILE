library;

enum DriverKycDocumentSection { driver, vehicle }

enum DriverKycDocumentType {
  photoFrontPermis,
  photoBackPermis,
  photoSelfPermis,
  photoCasier,
  insuranceCertificate,
  technicalInspection,
  vehicleRegistration,
  photoFrontVehicle,
}

extension DriverKycDocumentTypeX on DriverKycDocumentType {
  String get backendField => switch (this) {
    DriverKycDocumentType.photoFrontPermis => 'photoFrontPermis',
    DriverKycDocumentType.photoBackPermis => 'photoBackPermis',
    DriverKycDocumentType.photoSelfPermis => 'photoSelfPermis',
    DriverKycDocumentType.photoCasier => 'photoCasier',
    DriverKycDocumentType.insuranceCertificate => 'insuranceCertificate',
    DriverKycDocumentType.technicalInspection => 'technicalInspection',
    DriverKycDocumentType.vehicleRegistration => 'vehicleRegistration',
    DriverKycDocumentType.photoFrontVehicle => 'photoFrontVehicle',
  };

  String get label => switch (this) {
    DriverKycDocumentType.photoFrontPermis => 'Permis - recto',
    DriverKycDocumentType.photoBackPermis => 'Permis - verso',
    DriverKycDocumentType.photoSelfPermis => 'Selfie avec permis',
    DriverKycDocumentType.photoCasier => 'Casier judiciaire',
    DriverKycDocumentType.insuranceCertificate => 'Assurance véhicule',
    DriverKycDocumentType.technicalInspection => 'Visite technique',
    DriverKycDocumentType.vehicleRegistration => 'Carte grise',
    DriverKycDocumentType.photoFrontVehicle => 'Photo avant du véhicule',
  };

  String get helperText => switch (this) {
    DriverKycDocumentType.photoFrontPermis =>
      'Photo ou PDF du recto de votre permis.',
    DriverKycDocumentType.photoBackPermis =>
      'Photo ou PDF du verso de votre permis.',
    DriverKycDocumentType.photoSelfPermis =>
      'Prenez une photo nette de vous tenant votre permis.',
    DriverKycDocumentType.photoCasier =>
      'Vous pouvez ajouter un extrait de casier judiciaire lisible.',
    DriverKycDocumentType.insuranceCertificate =>
      'Document d\'assurance du véhicule demandé par l\'API KYC.',
    DriverKycDocumentType.technicalInspection =>
      'Ajoutez la visite technique en cours de validité.',
    DriverKycDocumentType.vehicleRegistration =>
      'Ajoutez la carte grise ou un PDF lisible.',
    DriverKycDocumentType.photoFrontVehicle =>
      'Photo nette de l\'avant du véhicule.',
  };

  DriverKycDocumentSection get section => switch (this) {
    DriverKycDocumentType.photoFrontPermis ||
    DriverKycDocumentType.photoBackPermis ||
    DriverKycDocumentType.photoSelfPermis ||
    DriverKycDocumentType.photoCasier => DriverKycDocumentSection.driver,
    DriverKycDocumentType.insuranceCertificate ||
    DriverKycDocumentType.technicalInspection ||
    DriverKycDocumentType.vehicleRegistration ||
    DriverKycDocumentType.photoFrontVehicle => DriverKycDocumentSection.vehicle,
  };
}

const List<DriverKycDocumentType> driverKycDriverDocuments = [
  DriverKycDocumentType.photoFrontPermis,
  DriverKycDocumentType.photoBackPermis,
  DriverKycDocumentType.photoSelfPermis,
  DriverKycDocumentType.photoCasier,
];

const List<DriverKycDocumentType> driverKycRequiredDocuments = [
  DriverKycDocumentType.photoFrontPermis,
  DriverKycDocumentType.photoBackPermis,
  DriverKycDocumentType.photoSelfPermis,
];

const List<DriverKycDocumentType> driverKycUpdateDocuments = [
  DriverKycDocumentType.photoFrontPermis,
  DriverKycDocumentType.photoBackPermis,
  DriverKycDocumentType.photoSelfPermis,
  DriverKycDocumentType.photoCasier,
];

const List<DriverKycDocumentType> driverKycVehicleDocuments = [
  DriverKycDocumentType.insuranceCertificate,
  DriverKycDocumentType.technicalInspection,
  DriverKycDocumentType.vehicleRegistration,
  DriverKycDocumentType.photoFrontVehicle,
];
