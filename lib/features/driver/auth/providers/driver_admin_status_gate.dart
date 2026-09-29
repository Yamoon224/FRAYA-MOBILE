library;

enum DriverAdminApprovalState {
  notSubmitted,
  pending,
  approved,
  rejected,
  other,
}

class DriverAdminStatusResult {
  const DriverAdminStatusResult({
    required this.kycState,
    required this.vehicleState,
    required this.hasVehicleId,
  });

  final DriverAdminApprovalState kycState;
  final DriverAdminApprovalState vehicleState;
  final bool hasVehicleId;

  bool get needsKycSubmission =>
      kycState == DriverAdminApprovalState.notSubmitted ||
      kycState == DriverAdminApprovalState.rejected;

  bool get isKycPending => kycState == DriverAdminApprovalState.pending;
  bool get isKycApproved => kycState == DriverAdminApprovalState.approved;
  bool get isKycRejected => kycState == DriverAdminApprovalState.rejected;
  bool get isVehiclePending => vehicleState == DriverAdminApprovalState.pending;
  bool get isVehicleApproved =>
      vehicleState == DriverAdminApprovalState.approved;
  bool get isVehicleRejected =>
      vehicleState == DriverAdminApprovalState.rejected;

  bool get isSubmittedAndPending =>
      hasVehicleId && (isKycPending || isVehiclePending);

  bool get canGoOnline => isKycApproved && hasVehicleId && isVehicleApproved;

  String? get blockingMessage {
    if (needsKycSubmission) {
      return isKycRejected
          ? 'Votre dossier KYC a été rejeté. Merci de renvoyer des documents lisibles.'
          : 'Vous devez soumettre votre dossier KYC avant de pouvoir conduire.';
    }
    if (isKycPending) {
      return 'Votre dossier KYC est en attente de validation par un administrateur.';
    }
    if (!hasVehicleId) {
      return 'Ajoutez votre véhicule à la prochaine étape pour pouvoir passer en ligne.';
    }
    if (!isVehicleApproved) {
      return 'Votre véhicule doit être validé par un administrateur avant de pouvoir conduire.';
    }
    return null;
  }
}

abstract final class DriverAdminStatusGate {
  static DriverAdminStatusResult fromUserData(Map<String, dynamic>? userData) {
    final vehicleId = userData?['vehicleId'];
    return DriverAdminStatusResult(
      kycState: _parse(userData?['kycStatus']),
      vehicleState: _parse(userData?['vehicleStatus']),
      hasVehicleId:
          vehicleId is int || (vehicleId is String && vehicleId.isNotEmpty),
    );
  }

  static DriverAdminApprovalState _parse(dynamic value) {
    final normalized = value?.toString().trim().toUpperCase();
    switch (normalized) {
      case 'APPROVED':
        return DriverAdminApprovalState.approved;
      case 'PENDING_VALIDATION':
        return DriverAdminApprovalState.pending;
      case 'REJECTED':
        return DriverAdminApprovalState.rejected;
      case 'NOT_SUBMITTED':
      case null:
      case '':
        return DriverAdminApprovalState.notSubmitted;
      default:
        return DriverAdminApprovalState.other;
    }
  }
}
