library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/driver_admin_status_gate.dart';
import '../../auth/providers/driver_auth_provider.dart';
import 'driver_registration_screen.dart';
import 'driver_vehicle_screen.dart';

/// Point d'entrée de la route véhicule : tant que le chauffeur n'a pas de véhicule (inscription),
/// il voit la page unique ; dès qu'un véhicule existe ou a été refusé, l'écran de suivi et de
/// correction d'avant reste inchangé.
class DriverVehicleEntryScreen extends ConsumerWidget {
  const DriverVehicleEntryScreen({super.key});

  /// Vrai quand l'inscription doit se faire sur la page unique.
  static bool usesRegistrationPage(DriverAdminStatusResult gate) =>
      !gate.hasVehicleId && !gate.isVehicleRejected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(driverAuthProvider);
    final gate = DriverAdminStatusGate.fromUserData(authState.userData);
    return usesRegistrationPage(gate)
        ? const DriverRegistrationScreen()
        : const DriverVehicleScreen();
  }
}
