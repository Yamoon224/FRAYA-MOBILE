library;

import 'package:flutter_riverpod/legacy.dart';

import '../../auth/providers/driver_auth_provider.dart';
import '../../auth/providers/driver_auth_session_parser.dart';
import '../../auth/providers/driver_submission_review_info.dart';
import '../../onboarding/providers/driver_onboarding_draft_dependencies.dart';
import '../../kyc/providers/driver_kyc_dependencies.dart';
import 'driver_vehicle_dependencies.dart';
import 'driver_vehicle_form_state.dart';
import 'driver_vehicle_provider.dart';

final driverVehicleFormProvider =
    StateNotifierProvider<DriverVehicleNotifier, DriverVehicleFormState>((ref) {
      return DriverVehicleNotifier(
        submitUseCase: ref.watch(submitDriverVehicleUseCaseProvider),
        draftRepository: ref.watch(driverOnboardingDraftRepositoryProvider),
        preparationService: ref.watch(driverDocumentPreparationServiceProvider),
        readDriverId: () =>
            _readDriverId(ref.read(driverAuthProvider).userData),
        readVehicleReviewData: () =>
            DriverSubmissionReviewInfoResolver.fromUserData(
              ref.read(driverAuthProvider).userData,
            ).vehicle,
        syncVehicleSession: (response) async {
          final authNotifier = ref.read(driverAuthProvider.notifier);
          final patch = DriverAuthSessionParser.extractVehicleSessionPatch(
            response,
          );
          if (patch != null) {
            await authNotifier.updateUserData(patch);
            await authNotifier.refreshProfile();
            return null;
          }

          final existingVehicleId = _readExistingVehicleId(
            ref.read(driverAuthProvider).userData,
          );
          if (existingVehicleId != null) {
            await authNotifier.updateUserData({
              'vehicleId': existingVehicleId,
              'vehicleStatus': 'PENDING_VALIDATION',
            });
            await authNotifier.refreshProfile();
            return null;
          }

          return 'Le véhicule a été créé mais son identifiant est introuvable dans la réponse serveur.';
        },
      );
    });

int? _readDriverId(Map<String, dynamic>? userData) {
  final raw = userData?['driverId'];
  if (raw is int) {
    return raw;
  }
  if (raw is String) {
    return int.tryParse(raw.trim());
  }
  return null;
}

int? _readExistingVehicleId(Map<String, dynamic>? userData) {
  final info = DriverSubmissionReviewInfoResolver.fromUserData(userData);
  return info.vehicleId;
}
