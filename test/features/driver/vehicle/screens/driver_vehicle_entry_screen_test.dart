import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_admin_status_gate.dart';
import 'package:fraya_mobile/features/driver/vehicle/screens/driver_vehicle_entry_screen.dart';

DriverAdminStatusResult _gate(Map<String, dynamic> userData) =>
    DriverAdminStatusGate.fromUserData(userData);

void main() {
  group('DriverVehicleEntryScreen.usesRegistrationPage', () {
    test("utilise la page unique tant qu'aucun véhicule n'existe", () {
      expect(
        DriverVehicleEntryScreen.usesRegistrationPage(_gate({'kycStatus': 'NOT_SUBMITTED'})),
        isTrue,
      );
      // Documents du chauffeur déjà envoyés, véhicule à ajouter : reprise sur la page unique.
      expect(
        DriverVehicleEntryScreen.usesRegistrationPage(_gate({'kycStatus': 'PENDING_VALIDATION'})),
        isTrue,
      );
    });

    test("garde l'écran de suivi dès qu'un véhicule existe", () {
      expect(
        DriverVehicleEntryScreen.usesRegistrationPage(
          _gate({'kycStatus': 'PENDING_VALIDATION', 'vehicleId': 12, 'vehicleStatus': 'PENDING_VALIDATION'}),
        ),
        isFalse,
      );
    });

    test("garde l'écran de correction quand le véhicule est refusé", () {
      expect(
        DriverVehicleEntryScreen.usesRegistrationPage(
          _gate({'kycStatus': 'APPROVED', 'vehicleId': 12, 'vehicleStatus': 'REJECTED'}),
        ),
        isFalse,
      );
    });
  });
}
