library;

import 'driver_kyc_document_file.dart';
import 'driver_kyc_document_type.dart';
import 'driver_vehicle_document_type.dart';

class DriverVehicleSubmission {
  const DriverVehicleSubmission({
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.range,
    required this.sidUserId,
    required this.kycDocuments,
    required this.documents,
    this.airConditioning = false,
  });

  final String brand;
  final String model;
  final String year;
  final String color;
  final String licensePlate;
  final String range;
  final int sidUserId;
  final Map<DriverKycDocumentType, DriverKycDocumentFile> kycDocuments;
  final Map<DriverVehicleDocumentType, DriverKycDocumentFile> documents;
  final bool airConditioning;
}
