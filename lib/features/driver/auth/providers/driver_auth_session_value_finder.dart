library;

typedef DriverStatusNormalizer = String Function(String? rawStatus);

class DriverAuthSessionValueFinder {
  static const List<String> _driverIdKeys = [
    'driverId',
    'driver_id',
    'idDriver',
  ];
  static const List<String> _userIdKeys = ['userId', 'id', 'sub'];
  static const List<String> _vehicleIdKeys = [
    'vehicleId',
    'vehicle_id',
    'idVehicle',
  ];

  static Map<String, dynamic>? normalizeCandidates(
    List<Map<String, dynamic>> candidates, {
    required DriverStatusNormalizer normalizeStatus,
  }) {
    if (candidates.isEmpty) {
      return null;
    }

    final userId = findFirstInt(candidates, _userIdKeys);
    final driverId = findFirstInt(candidates, _driverIdKeys) ?? userId;
    if (driverId == null && userId == null) {
      return null;
    }

    final normalized = <String, dynamic>{};
    for (final candidate in candidates.reversed) {
      normalized.addAll(candidate);
    }

    final vehicleId = findVehicleId(candidates);
    normalized['driverId'] = driverId;
    normalized['userId'] = userId ?? driverId;
    normalized['id'] ??= userId ?? driverId;
    if (vehicleId != null) {
      normalized['vehicleId'] = vehicleId;
    }
    normalized['kycStatus'] = normalizeStatus(findKycStatus(candidates));
    normalized['vehicleStatus'] = normalizeStatus(
      findVehicleStatus(candidates),
    );
    return normalized;
  }

  static int? findVehicleCreationId(List<Map<String, dynamic>> candidates) {
    return findFirstInt(candidates, [..._vehicleIdKeys, 'id']) ??
        findVehicleId(candidates);
  }

  static int? findVehicleId(List<Map<String, dynamic>> candidates) {
    final direct = findFirstInt(candidates, _vehicleIdKeys);
    if (direct != null) {
      return direct;
    }

    for (final candidate in candidates) {
      final nestedVehicle = extractVehicleMap(candidate);
      final nestedVehicleId = toInt(
        nestedVehicle?['id'] ?? nestedVehicle?['vehicleId'],
      );
      if (nestedVehicleId != null) {
        return nestedVehicleId;
      }

      final vehicles = candidate['vehicles'];
      if (vehicles is List) {
        for (final vehicle in vehicles) {
          if (vehicle is! Map) {
            continue;
          }
          final vehicleId = toInt(vehicle['id'] ?? vehicle['vehicleId']);
          if (vehicleId != null) {
            return vehicleId;
          }
        }
      }
    }
    return null;
  }

  static String? findKycStatus(List<Map<String, dynamic>> candidates) {
    for (final candidate in candidates) {
      final direct = asNonEmptyString(
        candidate['kycStatus'] ?? candidate['statusKyc'],
      );
      if (direct != null) {
        return direct;
      }

      final nested = extractNestedStatus(
        candidate,
        ['kyc', 'lastKyc'],
        ['kycStatus', 'status'],
      );
      if (nested != null) {
        return nested;
      }

      final kycs = candidate['kycs'];
      if (kycs is List) {
        for (final item in kycs) {
          if (item is! Map) {
            continue;
          }
          final status = asNonEmptyString(item['kycStatus'] ?? item['status']);
          if (status != null) {
            return status;
          }
        }
      }
    }
    return null;
  }

  static String? findVehicleStatus(List<Map<String, dynamic>> candidates) {
    for (final candidate in candidates) {
      final direct = asNonEmptyString(
        candidate['vehicleStatus'] ?? candidate['statusVehicle'],
      );
      if (direct != null) {
        return direct;
      }

      final nestedVehicle = extractVehicleMap(candidate);
      final nestedStatus = asNonEmptyString(
        nestedVehicle?['vehicleStatus'] ?? nestedVehicle?['status'],
      );
      if (nestedStatus != null) {
        return nestedStatus;
      }

      final vehicles = candidate['vehicles'];
      if (vehicles is List) {
        for (final item in vehicles) {
          if (item is! Map) {
            continue;
          }
          final status = asNonEmptyString(
            item['vehicleStatus'] ?? item['status'],
          );
          if (status != null) {
            return status;
          }
        }
      }
    }
    return null;
  }

  static int? findFirstInt(
    List<Map<String, dynamic>> candidates,
    List<String> keys,
  ) {
    for (final candidate in candidates) {
      for (final key in keys) {
        final value = toInt(candidate[key]);
        if (value != null) {
          return value;
        }
      }
    }
    return null;
  }

  static Map<String, dynamic>? extractVehicleMap(
    Map<String, dynamic> candidate,
  ) {
    final vehicle = candidate['vehicle'];
    if (vehicle is Map) {
      return Map<String, dynamic>.from(vehicle);
    }
    final vehicule = candidate['vehicule'];
    if (vehicule is Map) {
      return Map<String, dynamic>.from(vehicule);
    }
    return null;
  }

  static String? extractNestedStatus(
    Map<String, dynamic> candidate,
    List<String> parents,
    List<String> keys,
  ) {
    for (final parent in parents) {
      final value = candidate[parent];
      if (value is! Map) {
        continue;
      }
      for (final key in keys) {
        final status = asNonEmptyString(value[key]);
        if (status != null) {
          return status;
        }
      }
    }
    return null;
  }

  static int? toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static String? asNonEmptyString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
