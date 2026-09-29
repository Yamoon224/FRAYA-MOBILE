library;

import '../../../../domain/models/driver_vehicle_update.dart';
import '../../auth/providers/driver_auth_session_status_normalizer.dart';

class DriverVehicleSessionPatch {
  const DriverVehicleSessionPatch({
    required this.vehicleId,
    required this.status,
    required this.vehicle,
  });

  final int? vehicleId;
  final String status;
  final Map<String, dynamic> vehicle;

  Map<String, dynamic> toUserDataPatch() {
    final patch = <String, dynamic>{
      'vehicleStatus': status,
      'vehicle': vehicle,
    };
    if (vehicleId != null) {
      patch['vehicleId'] = vehicleId;
    }
    return patch;
  }
}

DriverVehicleSessionPatch buildVehicleSessionPatch({
  required Map<String, dynamic>? currentUserData,
  required Map<String, dynamic> response,
  required DriverVehicleUpdate update,
  required int? fallbackVehicleId,
}) {
  final payload = unwrapVehiclePayload(response);
  final vehicleId =
      readVehicleInt(payload['id'] ?? payload['vehicleId']) ??
      fallbackVehicleId;
  final status = DriverAuthSessionStatusNormalizer.normalize(
    pickVehicleText([payload['vehicleStatus'], payload['status']]) ??
        update.vehicleStatus,
  );
  final vehicle = <String, dynamic>{
    ...?extractVehicleMap(currentUserData),
    ...update.toJson(),
    ...payload,
    'vehicleStatus': status,
  };
  if (vehicleId != null) {
    vehicle['id'] = vehicleId;
  }
  return DriverVehicleSessionPatch(
    vehicleId: vehicleId,
    status: status,
    vehicle: vehicle,
  );
}

Map<String, dynamic> unwrapVehiclePayload(dynamic value) {
  var current = value;
  while (current is Map) {
    final next = current['data'] ?? current['vehicle'] ?? current['result'];
    if (next == null || identical(next, current)) break;
    current = next;
  }
  if (current is Map<String, dynamic>) return current;
  if (current is Map) return Map<String, dynamic>.from(current);
  return const {};
}

Map<String, dynamic>? extractVehicleMap(Map<String, dynamic>? userData) {
  if (userData == null) return null;
  for (final key in const ['vehicle', 'vehicule']) {
    final value = userData[key];
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  final vehicles = userData['vehicles'];
  if (vehicles is List) {
    for (final item in vehicles) {
      if (item is Map) return Map<String, dynamic>.from(item);
    }
  }
  return null;
}

int? readVehicleSidUserId(Map<String, dynamic>? userData) {
  for (final key in const ['driverId', 'userId', 'id']) {
    final value = readVehicleInt(userData?[key]);
    if (value != null) return value;
  }
  return null;
}

int? readVehicleInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

bool? readVehicleBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}

String? pickVehicleText(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text != 'null') return text;
  }
  return null;
}
