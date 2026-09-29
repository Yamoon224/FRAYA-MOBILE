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
      'Ajoutez l\'attestation d\'assurance en image ou PDF.',
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
