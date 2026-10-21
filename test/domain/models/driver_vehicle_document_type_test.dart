import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_document_type.dart';

void main() {
  test("l'assurance n'est plus obligatoire à l'inscription véhicule", () {
    expect(
      requiredVehicleDocuments,
      isNot(contains(DriverVehicleDocumentType.insuranceCertificate)),
    );
    expect(
      requiredVehicleDocuments,
      containsAll([
        DriverVehicleDocumentType.vehicleRegistration,
        DriverVehicleDocumentType.technicalInspection,
        DriverVehicleDocumentType.photoFrontVehicle,
      ]),
    );
    // Le type reste connu pour pouvoir l'ajouter plus tard.
    expect(DriverVehicleDocumentType.values, contains(DriverVehicleDocumentType.insuranceCertificate));
  });

  test("le selfie avec permis n'est plus demandé aux chauffeurs", () {
    expect(driverKycRequiredDocuments, isNot(contains(DriverKycDocumentType.photoSelfPermis)));
    expect(driverKycDriverDocuments, isNot(contains(DriverKycDocumentType.photoSelfPermis)));
    expect(driverKycUpdateDocuments, isNot(contains(DriverKycDocumentType.photoSelfPermis)));
  });
}
