import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_document_type.dart';

void main() {
  group('DriverVehicleDocumentTypeX', () {
    test('exposes backend fields for all supported vehicle documents', () {
      expect(
        DriverVehicleDocumentType.values.map((type) => type.backendField),
        [
          'insuranceCertificate',
          'technicalInspection',
          'vehicleRegistration',
          'photoFrontVehicle',
          'photoRearVehicle',
          'photoLeftVehicle',
          'photoRightVehicle',
          'photoInteriorVehicle',
        ],
      );
    });

    test('provides non empty labels and helper texts', () {
      for (final type in DriverVehicleDocumentType.values) {
        expect(type.label, isNotEmpty);
        expect(type.helperText, isNotEmpty);
      }
    });
  });
}
