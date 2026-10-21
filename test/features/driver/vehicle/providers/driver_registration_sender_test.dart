import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/vehicle/providers/driver_registration_sender.dart';

void main() {
  test("envoie d'abord les documents du chauffeur puis le véhicule", () async {
    final calls = <String>[];

    final result = await sendDriverRegistration(
      needsKycSubmission: true,
      submitKyc: () async {
        calls.add('kyc');
        return true;
      },
      submitVehicle: () async => calls.add('vehicule'),
    );

    expect(calls, ['kyc', 'vehicule']);
    expect(result, DriverRegistrationSendResult.vehicleAttempted);
  });

  test("s'arrête si l'envoi des documents du chauffeur échoue", () async {
    final calls = <String>[];

    final result = await sendDriverRegistration(
      needsKycSubmission: true,
      submitKyc: () async {
        calls.add('kyc');
        return false;
      },
      submitVehicle: () async => calls.add('vehicule'),
    );

    expect(calls, ['kyc']);
    expect(result, DriverRegistrationSendResult.kycFailed);
  });

  test('reprise : documents déjà envoyés, seul le véhicule est relancé', () async {
    final calls = <String>[];

    final result = await sendDriverRegistration(
      needsKycSubmission: false,
      submitKyc: () async {
        calls.add('kyc');
        return true;
      },
      submitVehicle: () async => calls.add('vehicule'),
    );

    expect(calls, ['vehicule']);
    expect(result, DriverRegistrationSendResult.vehicleAttempted);
  });
}
