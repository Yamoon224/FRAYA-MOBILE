import 'dart:convert';

import '../../../../core/utils/constants.dart';
import '../../../../data/sources/local_storage.dart';
import 'driver_auth_session_candidate_builder.dart';
import 'driver_auth_session_parser.dart';
import 'driver_auth_session_value_finder.dart';

class DriverAuthLocalSession {
  Future<Map<String, dynamic>?> restore() async {
    final userDataStr = await LocalStorage.instance.getSecure(
      AppConstants.driverAuthUserDataKey,
    );
    final token = await LocalStorage.instance.getSecure(
      AppConstants.driverAccessTokenKey,
    );
    if (token == null || userDataStr == null) {
      return null;
    }

    final decoded = jsonDecode(userDataStr);
    if (decoded is! Map) {
      throw const FormatException('driver_auth_user_data_invalid');
    }
    return DriverAuthSessionParser.normalizeStoredUserData(
      Map<String, dynamic>.from(decoded),
    );
  }

  Future<void> persist(String token, Map<String, dynamic> userData) async {
    await LocalStorage.instance.setSecure(
      AppConstants.driverAccessTokenKey,
      token,
    );
    await _save(userData);
  }

  Future<Map<String, dynamic>?> update(
    Map<String, dynamic> currentUserData,
    Map<String, dynamic> newData,
  ) async {
    final updatedData = Map<String, dynamic>.from(currentUserData)
      ..addAll(newData);
    return _normalizeAndSave(updatedData);
  }

  Future<Map<String, dynamic>?> mergeProfile(
    Map<String, dynamic> currentUserData,
    Map<String, dynamic> profile,
  ) async {
    final profileData = DriverAuthSessionParser.buildUserData(profile);
    if (profileData == null) {
      return null;
    }

    final profileCandidates = DriverAuthSessionCandidateBuilder.buildCandidates(
      profile,
    );
    final profileProvidesKycStatus = _providesKycStatus(profileCandidates);
    final profileProvidesVehicleStatus = _providesVehicleStatus(
      profileCandidates,
    );

    final mergedData = Map<String, dynamic>.from(currentUserData)
      ..addAll(profileData);
    _preserveStatusIfAbsent(
      target: mergedData,
      source: currentUserData,
      key: 'kycStatus',
      profileProvidesStatus: profileProvidesKycStatus,
    );
    _preserveStatusIfAbsent(
      target: mergedData,
      source: currentUserData,
      key: 'vehicleStatus',
      profileProvidesStatus: profileProvidesVehicleStatus,
    );
    return _normalizeAndSave(mergedData);
  }

  void _preserveStatusIfAbsent({
    required Map<String, dynamic> target,
    required Map<String, dynamic> source,
    required String key,
    required bool profileProvidesStatus,
  }) {
    final existingStatus = source[key]?.toString();
    if (profileProvidesStatus ||
        existingStatus == null ||
        existingStatus == 'NOT_SUBMITTED' ||
        target[key] != 'NOT_SUBMITTED') {
      return;
    }

    target[key] = existingStatus;
  }

  bool _providesKycStatus(List<Map<String, dynamic>> candidates) {
    for (final candidate in candidates) {
      if (_hasStatus(candidate['kycStatus']) ||
          _hasStatus(candidate['statusKyc'])) {
        return true;
      }
      if (_containsNestedStatus(
        candidate,
        ['kyc', 'lastKyc'],
        ['kycStatus', 'status'],
      )) {
        return true;
      }
      if (_containsStatusInList(candidate['kycs'], ['kycStatus', 'status'])) {
        return true;
      }
    }
    return false;
  }

  bool _providesVehicleStatus(List<Map<String, dynamic>> candidates) {
    for (final candidate in candidates) {
      if (_hasStatus(candidate['vehicleStatus']) ||
          _hasStatus(candidate['statusVehicle'])) {
        return true;
      }
      if (_containsNestedStatus(
            candidate,
            ['vehicle', 'vehicule'],
            ['vehicleStatus', 'status'],
          ) ||
          _containsStatusInList(candidate['vehicles'], [
            'vehicleStatus',
            'status',
          ])) {
        return true;
      }
    }
    return false;
  }

  bool _containsNestedStatus(
    Map<String, dynamic> candidate,
    List<String> parents,
    List<String> keys,
  ) {
    for (final parent in parents) {
      final nested = candidate[parent];
      if (nested is! Map) {
        continue;
      }
      for (final key in keys) {
        if (_hasStatus(nested[key])) {
          return true;
        }
      }
    }
    return false;
  }

  bool _containsStatusInList(dynamic items, List<String> keys) {
    if (items is! List) {
      return false;
    }

    for (final item in items) {
      if (item is! Map) {
        continue;
      }
      for (final key in keys) {
        if (_hasStatus(item[key])) {
          return true;
        }
      }
    }
    return false;
  }

  bool _hasStatus(dynamic value) {
    return DriverAuthSessionValueFinder.asNonEmptyString(value) != null;
  }

  Future<Map<String, dynamic>?> _normalizeAndSave(
    Map<String, dynamic> userData,
  ) async {
    final normalized = DriverAuthSessionParser.normalizeStoredUserData(
      userData,
    );
    if (normalized == null) {
      return null;
    }

    await _save(normalized);
    return normalized;
  }

  Future<void> _save(Map<String, dynamic> userData) async {
    await LocalStorage.instance.setSecure(
      AppConstants.driverAuthUserDataKey,
      jsonEncode(userData),
    );
  }
}
