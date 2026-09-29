library;

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
}
