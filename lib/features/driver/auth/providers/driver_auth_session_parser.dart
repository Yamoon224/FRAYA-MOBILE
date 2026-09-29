library;

import 'driver_auth_session_candidate_builder.dart';
import 'driver_auth_session_status_normalizer.dart';
import 'driver_auth_session_value_finder.dart';

class DriverAuthSessionParser {
  static String? extractToken(Map<String, dynamic> response) {
    final payload = DriverAuthSessionCandidateBuilder.extractPayload(response);
    return DriverAuthSessionValueFinder.asNonEmptyString(
      payload['access_token'] ??
          payload['accessToken'] ??
          response['access_token'] ??
          response['accessToken'],
    );
  }

  static Map<String, dynamic>? buildUserData(Map<String, dynamic> response) {
    final candidates = DriverAuthSessionCandidateBuilder.buildCandidates(response);
    return DriverAuthSessionValueFinder.normalizeCandidates(
      candidates,
      normalizeStatus: DriverAuthSessionStatusNormalizer.normalize,
    );
  }

  static Map<String, dynamic>? normalizeStoredUserData(
    Map<String, dynamic> userData,
  ) {
    return DriverAuthSessionValueFinder.normalizeCandidates(
      [Map<String, dynamic>.from(userData)],
      normalizeStatus: DriverAuthSessionStatusNormalizer.normalize,
    );
  }

  static Map<String, dynamic>? extractVehicleSessionPatch(
    Map<String, dynamic> response,
  ) {
    final candidates = DriverAuthSessionCandidateBuilder.buildCandidates(response);
    final vehicleId =
        DriverAuthSessionValueFinder.findVehicleCreationId(candidates);
    if (vehicleId == null) {
      return null;
    }

    final vehicleStatus =
        DriverAuthSessionValueFinder.findVehicleStatus(candidates);
    return {
      'vehicleId': vehicleId,
      'vehicleStatus': DriverAuthSessionStatusNormalizer.normalize(
        vehicleStatus ?? 'PENDING_VALIDATION',
      ),
    };
  }
}
