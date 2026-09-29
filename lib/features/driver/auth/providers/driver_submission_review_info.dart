library;

class DriverVehicleReviewData {
  const DriverVehicleReviewData({
    this.brand,
    this.model,
    this.year,
    this.color,
    this.licensePlate,
    this.range,
  });

  final String? brand;
  final String? model;
  final String? year;
  final String? color;
  final String? licensePlate;
  final String? range;

  bool get hasAnyValue =>
      brand != null ||
      model != null ||
      year != null ||
      color != null ||
      licensePlate != null ||
      range != null;
}

class DriverSubmissionReviewInfo {
  const DriverSubmissionReviewInfo({
    this.kycId,
    this.vehicleId,
    this.kycRejectionReason,
    this.vehicleRejectionReason,
    this.vehicle,
  });

  final int? kycId;
  final int? vehicleId;
  final String? kycRejectionReason;
  final String? vehicleRejectionReason;
  final DriverVehicleReviewData? vehicle;
}

abstract final class DriverSubmissionReviewInfoResolver {
  static DriverSubmissionReviewInfo fromUserData(
    Map<String, dynamic>? userData,
  ) {
    if (userData == null) {
      return const DriverSubmissionReviewInfo();
    }

    final kyc = _extractKyc(userData);
    final vehicle = _extractVehicle(userData);
    final kycCandidates = [?kyc, userData];
    final vehicleCandidates = [?vehicle, userData];

    return DriverSubmissionReviewInfo(
      kycId: _findInt(kycCandidates, const ['id', 'kycId', 'kyc_id']),
      vehicleId: _findInt(vehicleCandidates, const [
        'id',
        'vehicleId',
        'vehicle_id',
      ]),
      kycRejectionReason: _findText(kycCandidates, _kycRejectionKeys),
      vehicleRejectionReason: _findText(
        vehicleCandidates,
        _vehicleRejectionKeys,
      ),
      vehicle: _buildVehicleData(userData, vehicle),
    );
  }

  static const _kycRejectionKeys = [
    'kycRejectionReason',
    'kycRejectReason',
    'rejectionReason',
    'rejectReason',
    'adminComment',
    'comment',
    'reason',
    'description',
    'message',
  ];

  static const _vehicleRejectionKeys = [
    'vehicleRejectionReason',
    'vehicleRejectReason',
    'rejectionReason',
    'rejectReason',
    'adminComment',
    'comment',
    'reason',
    'description',
    'message',
  ];

  static DriverVehicleReviewData? _buildVehicleData(
    Map<String, dynamic> userData,
    Map<String, dynamic>? vehicle,
  ) {
    final data = DriverVehicleReviewData(
      brand: _firstText([vehicle?['brand'], userData['brand']]),
      model: _firstText([vehicle?['model'], userData['model']]),
      year: _firstText([vehicle?['year'], userData['year']]),
      color: _firstText([vehicle?['color'], userData['color']]),
      licensePlate: _firstText([
        vehicle?['licensePlate'],
        vehicle?['matricule'],
        userData['licensePlate'],
        userData['matricule'],
      ]),
      range: _firstText([
        vehicle?['requestedRange'],
        vehicle?['range'],
        userData['requestedRange'],
        userData['range'],
      ]),
    );
    return data.hasAnyValue ? data : null;
  }

  static Map<String, dynamic>? _extractKyc(Map<String, dynamic> userData) {
    final direct = _nestedMap(userData, const ['kyc', 'lastKyc']);
    if (direct != null) return direct;
    return _firstMap(userData['kycs']);
  }

  static Map<String, dynamic>? _extractVehicle(Map<String, dynamic> userData) {
    final direct = _nestedMap(userData, const ['vehicle', 'vehicule']);
    if (direct != null) return direct;
    return _firstMap(userData['vehicles']);
  }

  static Map<String, dynamic>? _nestedMap(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }
    return null;
  }

  static Map<String, dynamic>? _firstMap(dynamic value) {
    if (value is! List) return null;
    for (final item in value) {
      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  static int? _findInt(List<Map<String, dynamic>> maps, List<String> keys) {
    for (final map in maps) {
      for (final key in keys) {
        final value = _toInt(map[key]);
        if (value != null) return value;
      }
    }
    return null;
  }

  static String? _findText(List<Map<String, dynamic>> maps, List<String> keys) {
    for (final map in maps) {
      for (final key in keys) {
        final value = _asText(map[key]);
        if (value != null) return value;
      }
    }
    return null;
  }

  static String? _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = _asText(value);
      if (text != null) return text;
    }
    return null;
  }

  static String? _asText(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
