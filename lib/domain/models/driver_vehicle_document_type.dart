library;

enum DriverVehicleDocumentType {
  insuranceCertificate,
  technicalInspection,
  vehicleRegistration,
  photoFrontVehicle,
  photoRearVehicle,
  photoLeftVehicle,
  photoRightVehicle,
  photoInteriorVehicle,
}

/// Les cinq photos exigées pour demander une gamme supérieure à celle du véhicule.
const List<DriverVehicleDocumentType> vehicleRangePhotoTypes = [
  DriverVehicleDocumentType.photoFrontVehicle,
  DriverVehicleDocumentType.photoRearVehicle,
  DriverVehicleDocumentType.photoLeftVehicle,
  DriverVehicleDocumentType.photoRightVehicle,
  DriverVehicleDocumentType.photoInteriorVehicle,
];

/// Niveau d'une gamme (MAGIC < GLADIATEUR < ELITE) ; 0 si inconnue.
int vehicleRangeLevel(String? range) => switch (range?.trim().toUpperCase()) {
  'MAGIC' => 1,
  'GLADIATEUR' => 2,
  'ELITE' => 3,
  _ => 0,
};

/// Documents véhicule obligatoires à l'inscription : l'assurance peut être ajoutée plus tard.
final List<DriverVehicleDocumentType> requiredVehicleDocuments =
    DriverVehicleDocumentType.values
        .where((type) => type != DriverVehicleDocumentType.insuranceCertificate)
        .toList(growable: false);

extension DriverVehicleDocumentTypeX on DriverVehicleDocumentType {
  String get backendField => switch (this) {
    DriverVehicleDocumentType.insuranceCertificate => 'insuranceCertificate',
    DriverVehicleDocumentType.technicalInspection => 'technicalInspection',
    DriverVehicleDocumentType.vehicleRegistration => 'vehicleRegistration',
    DriverVehicleDocumentType.photoFrontVehicle => 'photoFrontVehicle',
    DriverVehicleDocumentType.photoRearVehicle => 'photoRearVehicle',
    DriverVehicleDocumentType.photoLeftVehicle => 'photoLeftVehicle',
    DriverVehicleDocumentType.photoRightVehicle => 'photoRightVehicle',
    DriverVehicleDocumentType.photoInteriorVehicle => 'photoInteriorVehicle',
  };

  String get label => switch (this) {
    DriverVehicleDocumentType.insuranceCertificate => 'Assurance véhicule',
    DriverVehicleDocumentType.technicalInspection => 'Visite technique',
    DriverVehicleDocumentType.vehicleRegistration => 'Carte grise',
    DriverVehicleDocumentType.photoFrontVehicle => 'Photo avant du véhicule',
    DriverVehicleDocumentType.photoRearVehicle => 'Photo arrière du véhicule',
    DriverVehicleDocumentType.photoLeftVehicle =>
      'Photo côté gauche du véhicule',
    DriverVehicleDocumentType.photoRightVehicle =>
      'Photo côté droit du véhicule',
    DriverVehicleDocumentType.photoInteriorVehicle =>
      'Photo intérieure du véhicule',
  };

  String get helperText => switch (this) {
    DriverVehicleDocumentType.insuranceCertificate =>
      'Attestation d\'assurance en image ou PDF (facultatif pour l\'instant, à ajouter plus tard).',
    DriverVehicleDocumentType.technicalInspection =>
      'Ajoutez la visite technique en cours de validité.',
    DriverVehicleDocumentType.vehicleRegistration =>
      'Ajoutez la carte grise du véhicule.',
    DriverVehicleDocumentType.photoFrontVehicle =>
      'Ajoutez une photo nette de l\'avant du véhicule.',
    DriverVehicleDocumentType.photoRearVehicle =>
      'Ajoutez une photo nette de l\'arrière du véhicule.',
    DriverVehicleDocumentType.photoLeftVehicle =>
      'Ajoutez une photo nette du côté gauche du véhicule.',
    DriverVehicleDocumentType.photoRightVehicle =>
      'Ajoutez une photo nette du côté droit du véhicule.',
    DriverVehicleDocumentType.photoInteriorVehicle =>
      'Ajoutez une photo nette de l\'intérieur du véhicule.',
  };
}
