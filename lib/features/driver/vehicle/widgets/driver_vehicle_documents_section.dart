library;

import 'package:flutter/material.dart';

import '../../../../domain/models/driver_kyc_document_file.dart';
import '../../../../domain/models/driver_vehicle_document_type.dart';
import 'driver_vehicle_document_picker_tile.dart';

class DriverVehicleDocumentsSection extends StatelessWidget {
  const DriverVehicleDocumentsSection({
    super.key,
    required this.documents,
    required this.enabled,
    required this.onSelect,
    required this.onRemove,
    this.processingDocuments = const {},
  });

  final Map<DriverVehicleDocumentType, DriverKycDocumentFile> documents;
  final bool enabled;
  final ValueChanged<DriverVehicleDocumentType> onSelect;
  final ValueChanged<DriverVehicleDocumentType> onRemove;
  final Set<DriverVehicleDocumentType> processingDocuments;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: DriverVehicleDocumentType.values
          .map(
            (type) => DriverVehicleDocumentPickerTile(
              type: type,
              document: documents[type],
              enabled: enabled && !processingDocuments.contains(type),
              isProcessing: processingDocuments.contains(type),
              onSelect: () => onSelect(type),
              onRemove: () => onRemove(type),
            ),
          )
          .toList(),
    );
  }
}
