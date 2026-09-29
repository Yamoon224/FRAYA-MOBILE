library;

import '../../../../domain/models/driver_kyc_document_type.dart';

enum DriverProfileDocumentStatus {
  valid,
  expiringSoon,
  pending,
  rejected,
  missing,
}

class DriverProfileVehicleViewData {
  const DriverProfileVehicleViewData({
    required this.name,
    required this.subtitle,
    required this.plate,
    required this.rangeLabel,
  });

  final String name;
  final String subtitle;
  final String plate;
  final String rangeLabel;
}

class DriverProfileDocumentViewData {
  const DriverProfileDocumentViewData({
    required this.type,
    required this.section,
    required this.label,
    required this.expiryLabel,
    required this.statusLabel,
    required this.status,
    this.documentUrl,
  });

  final DriverKycDocumentType type;
  final DriverKycDocumentSection section;
  final String label;
  final String expiryLabel;
  final String statusLabel;
  final DriverProfileDocumentStatus status;
  final String? documentUrl;
}

class DriverProfileViewData {
  const DriverProfileViewData({
    this.vehicle,
    this.documents = const <DriverProfileDocumentViewData>[],
    this.hasDocumentEndpoint = false,
  });

  final DriverProfileVehicleViewData? vehicle;
  final List<DriverProfileDocumentViewData> documents;
  final bool hasDocumentEndpoint;
}
