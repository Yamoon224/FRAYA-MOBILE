library;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/utils/map_parsing_utils.dart';

int? extractDriverRideDriverId(
  Map<String, dynamic> ride,
  Map<String, dynamic> driver,
  Map<String, dynamic> vehicle,
) {
  return toInt(
    ride['driverId'] ??
        driver['id'] ??
        driver['userId'] ??
        nestedMap(driver, ['sidUser'])?['id'] ??
        vehicle['sidUserId'] ??
        nestedMap(vehicle, ['sidUser'])?['id'],
  );
}

LatLng? parseDriverRideDriverLocation(
  Map<String, dynamic> ride,
  Map<String, dynamic> driver,
) {
  final fallback = parseLatLng(
    driver,
    const ['lat', 'latitude'],
    const ['lng', 'longitude'],
  );
  final location = parseLatLng(
    ride,
    const ['driverLat', 'driverLatitude'],
    const ['driverLng', 'driverLongitude'],
    fallback: fallback,
  );
  final hasDriverCoordinates =
      ride['driverLat'] != null ||
      ride['driverLatitude'] != null ||
      driver['lat'] != null ||
      driver['latitude'] != null;
  return hasDriverCoordinates ? location : null;
}

DateTime? parseDriverRideDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

String firstNonEmptyDriverRideValue(List<dynamic> values) {
  return firstString(values, fallback: '');
}

String? optionalDriverRideString(List<dynamic> values) {
  final value = firstNonEmptyDriverRideValue(values);
  return value.isEmpty ? null : value;
}

String? fullNameFromDriverRideUser(Map<String, dynamic> user) {
  final firstName = optionalDriverRideString([
    user['firstNames'],
    user['firstName'],
  ]);
  final lastName = optionalDriverRideString([user['lastName'], user['name']]);
  final fullName = [firstName, lastName]
      .whereType<String>()
      .where((value) => value.trim().isNotEmpty)
      .join(' ')
      .trim();
  return fullName.isEmpty ? null : fullName;
}
