library;

import '../../../../domain/models/driver_kyc_document_file.dart';
import '../../../../domain/models/driver_kyc_document_type.dart';
import '../../../../domain/models/driver_onboarding_draft.dart';
import 'driver_vehicle_form_state.dart';

const List<DriverKycDocumentType> requiredVehicleKycDocuments = [
  DriverKycDocumentType.photoFrontPermis,
  DriverKycDocumentType.photoBackPermis,
  DriverKycDocumentType.photoSelfPermis,
];

DriverVehicleFormState restoreVehicleFormState(
  DriverVehicleFormState current,
  DriverOnboardingDraft draft,
) {
  return current.copyWith(
    brand: draft.brand ?? current.brand,
    model: draft.model ?? current.model,
    year: draft.year ?? current.year,
    color: draft.color ?? current.color,
    licensePlate: draft.licensePlate ?? current.licensePlate,
    selectedRange: draft.range ?? current.selectedRange,
    airConditioning: draft.airConditioning ?? current.airConditioning,
    documents: draft.vehicleDocuments.isEmpty
        ? current.documents
        : draft.vehicleDocuments,
  );
}

Map<DriverKycDocumentType, DriverKycDocumentFile>? extractVehicleKycDocuments(
  DriverOnboardingDraft? draft,
) {
  if (draft == null) {
    return null;
  }

  final documents = <DriverKycDocumentType, DriverKycDocumentFile>{};
  for (final type in requiredVehicleKycDocuments) {
    final document = draft.kycDocuments[type];
    if (document == null) {
      return null;
    }
    documents[type] = document;
  }
  return documents;
}
