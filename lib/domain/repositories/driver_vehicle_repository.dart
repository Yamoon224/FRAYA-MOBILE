library;

import '../models/driver_kyc_document_file.dart';
import '../models/driver_vehicle_document_type.dart';
import '../models/driver_vehicle_submission.dart';
import '../models/driver_vehicle_update.dart';

abstract class DriverVehicleRepository {
  Future<Map<String, dynamic>> submitVehicle({
    required DriverVehicleSubmission submission,
  });

  Future<Map<String, dynamic>> updateVehicle({
    required int vehicleId,
    required DriverVehicleUpdate update,
  });

  Future<Map<String, dynamic>> updateSecondaryRange({
    required int vehicleId,
    required String? secondaryRange,
  });

  Future<Map<String, dynamic>> requestSecondaryRange({
    required int vehicleId,
    required String secondaryRange,
    required Map<DriverVehicleDocumentType, DriverKycDocumentFile> photos,
  });
}
