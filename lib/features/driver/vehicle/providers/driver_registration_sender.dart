library;

/// Issue de l'envoi du dossier d'inscription chauffeur (documents puis véhicule).
enum DriverRegistrationSendResult {
  /// Les documents du chauffeur n'ont pas pu être envoyés : rien d'autre n'a été tenté.
  kycFailed,

  /// Les documents du chauffeur sont envoyés (ou l'étaient déjà) ; l'envoi du véhicule a été tenté.
  /// Son succès ou son échec est signalé par le formulaire véhicule lui-même.
  vehicleAttempted,
}

/// Enchaîne les deux envois de la page unique d'inscription.
///
/// 1. Documents du chauffeur (si [needsKycSubmission]) : en cas d'échec on s'arrête là.
/// 2. Véhicule : s'il échoue après le succès de l'étape 1, les documents du chauffeur restent
///    envoyés et le chauffeur ne relance que le véhicule (reprise).
Future<DriverRegistrationSendResult> sendDriverRegistration({
  required bool needsKycSubmission,
  required Future<bool> Function() submitKyc,
  required Future<void> Function() submitVehicle,
}) async {
  if (needsKycSubmission) {
    final kycSent = await submitKyc();
    if (!kycSent) return DriverRegistrationSendResult.kycFailed;
  }
  await submitVehicle();
  return DriverRegistrationSendResult.vehicleAttempted;
}
