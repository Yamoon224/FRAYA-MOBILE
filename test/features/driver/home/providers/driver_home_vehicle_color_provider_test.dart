import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/theme/app_colors.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_vehicle_color_provider.dart';

void main() {
  group('DriverHomeVehicleColorResolver', () {
    test('uses vehicle.color first when available', () {
      final color = DriverHomeVehicleColorResolver.resolve({
        'vehicle': {'color': 'bleu'},
        'vehicleColor': 'rouge',
      });

      expect(color, const Color(0xFF1976D2));
    });

    test('uses vehicule.color when vehicle.color is missing', () {
      final color = DriverHomeVehicleColorResolver.resolve({
        'vehicule': {'color': 'vert'},
      });

      expect(color, const Color(0xFF2E7D32));
    });

    test('uses vehicleColor when nested vehicle maps are missing', () {
      final color = DriverHomeVehicleColorResolver.resolve({
        'vehicleColor': '#D4A843',
      });

      expect(color, const Color(0xFFD4A843));
    });

    test('falls back to AppColors.primary when no color is available', () {
      final color = DriverHomeVehicleColorResolver.resolve({
        'driverId': 42,
      });

      expect(color, AppColors.primary);
    });
  });
}
