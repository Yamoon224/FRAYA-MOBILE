library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/vehicle_ui_utils.dart';
import '../../auth/providers/driver_auth_provider.dart';

final driverVehicleMarkerColorProvider = Provider<Color>((ref) {
  final userData = ref.watch(driverAuthProvider.select((state) => state.userData));
  return DriverHomeVehicleColorResolver.resolve(userData);
});

abstract final class DriverHomeVehicleColorResolver {
  static Color resolve(Map<String, dynamic>? userData) {
    final vehicle = _asMap(userData?['vehicle']);
    final vehicule = _asMap(userData?['vehicule']);
    final rawColor = _asString(vehicle?['color']) ??
        _asString(vehicule?['color']) ??
        _asString(userData?['vehicleColor']) ??
        _asString(userData?['color']);

    if (rawColor == null) {
      return AppColors.primary;
    }
    return VehicleUiUtils.colorFromVehicleName(rawColor);
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
