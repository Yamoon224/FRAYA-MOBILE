library;

class NearbyDriverMovingEvent {
  NearbyDriverMovingEvent({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    this.bearing,
    this.vehicleColorRaw,
  });

  final String driverId;
  final double latitude;
  final double longitude;
  final double? bearing;
  final String? vehicleColorRaw;

  static NearbyDriverMovingEvent? tryParse(dynamic payload) {
    final map = _asMap(payload);
    if (map == null) return null;

    final driverId = _firstNonEmpty([
      map['driverId'],
      map['id'],
      map['sidUserId'],
      map['userId'],
    ]);
    if (driverId == null) return null;

    final latitude = _toDouble(map['latitude'] ?? map['lat']);
    final longitude = _toDouble(map['longitude'] ?? map['lng'] ?? map['long']);
    if (latitude == null || longitude == null) return null;

    return NearbyDriverMovingEvent(
      driverId: driverId,
      latitude: latitude,
      longitude: longitude,
      bearing: _toDouble(map['bearing'] ?? map['heading']),
      vehicleColorRaw: _firstNonEmpty([
        map['vehicleColor'],
        map['carColor'],
        map['color'],
      ]),
    );
  }
}

class RidePositionUpdateEvent {
  RidePositionUpdateEvent({
    required this.latitude,
    required this.longitude,
    this.rideId,
    this.bearing,
  });

  final String? rideId;
  final double latitude;
  final double longitude;
  final double? bearing;

  static RidePositionUpdateEvent? tryParse(dynamic payload) {
    final map = _asMap(payload);
    if (map == null) return null;

    final latitude = _toDouble(
      map['driverLat'] ?? map['latitude'] ?? map['lat'],
    );
    final longitude = _toDouble(
      map['driverLng'] ?? map['longitude'] ?? map['lng'] ?? map['long'],
    );
    if (latitude == null || longitude == null) return null;

    return RidePositionUpdateEvent(
      rideId: _firstNonEmpty([map['rideId'], map['id'], map['courseId']]),
      latitude: latitude,
      longitude: longitude,
      bearing: _toDouble(map['bearing'] ?? map['heading']),
    );
  }
}

class RideAcceptedEvent {
  RideAcceptedEvent({required this.rideId, this.passengerId});

  final String rideId;
  final int? passengerId;

  static RideAcceptedEvent? tryParse(dynamic payload) {
    final map = _asMap(payload);
    if (map == null) return null;

    final rideId = _firstNonEmpty([map['rideId'], map['id'], map['courseId']]);
    if (rideId == null) return null;

    return RideAcceptedEvent(
      rideId: rideId,
      passengerId: _toInt(map['passengerId'] ?? map['userId']),
    );
  }
}

enum RideChangeActor { driver, passenger, unknown }

class DriverRideStatusRealtimeEvent {
  DriverRideStatusRealtimeEvent({
    required this.rideId,
    required this.status,
    required this.updatedAt,
    this.reason,
    this.changedBy,
  });

  final String rideId;
  final String status;
  final DateTime updatedAt;
  final String? reason;
  final String? changedBy;

  bool get isCancelled => status.toUpperCase() == 'CANCELLED';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  RideChangeActor get changeActor => _parseRideChangeActor(changedBy);

  static DriverRideStatusRealtimeEvent? tryParse(
    dynamic payload, {
    String? fallbackStatus,
  }) {
    final map = _extractRealtimeData(payload);
    if (map == null) return null;

    final rideId = _firstNonEmpty([map['rideId'], map['id'], map['courseId']]);
    final status =
        _firstNonEmpty([map['status'], map['rideStatus'], map['statusRace']]) ??
        fallbackStatus;
    if (rideId == null || status == null) return null;

    final updatedAtRaw = map['updatedAt'] ?? map['timestamp'] ?? map['date'];
    final updatedAt = _toDateTime(updatedAtRaw) ?? DateTime.now();

    return DriverRideStatusRealtimeEvent(
      rideId: rideId,
      status: status,
      updatedAt: updatedAt,
      reason: _firstNonEmpty([map['reason'], map['message'], map['motif']]),
      changedBy: _firstNonEmpty([
        map['cancelledBy'],
        map['canceledBy'],
        map['changedBy'],
        map['source'],
        map['by'],
        map['actor'],
      ]),
    );
  }
}

class NewRideOfferEvent {
  NewRideOfferEvent({required this.rideId});

  final String rideId;

  static NewRideOfferEvent? tryParse(dynamic payload) {
    final map = _extractRealtimeData(payload);
    if (map == null) {
      return null;
    }
    final type = _normalizeType(
      _firstNonEmpty([map['type'], map['event'], map['notificationType']]),
    );
    if (type != null && !_newRideOfferTypes.contains(type)) {
      return null;
    }
    final rideId = _firstNonEmpty([map['rideId'], map['id'], map['courseId']]);
    if (rideId == null) return null;
    return NewRideOfferEvent(rideId: rideId);
  }
}

const Set<String> _newRideOfferTypes = {
  'new_ride_available',
  'ride_notification',
  'new_ride',
  'ride_available',
};

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

Map<String, dynamic>? _extractRealtimeData(dynamic value) {
  final map = _asMap(value);
  if (map == null) return null;
  final data = <String, dynamic>{...map};
  final nested = _asMap(map['data']);
  if (nested != null) {
    data.addAll(nested);
  }
  final ride = _asMap(data['ride']);
  if (ride != null) {
    data.addAll(ride);
  }
  final course = _asMap(data['course']);
  if (course != null) {
    data.addAll(course);
  }
  return data;
}

String? _normalizeType(String? value) {
  final text = value?.trim().toLowerCase();
  return text == null || text.isEmpty ? null : text;
}

RideChangeActor _parseRideChangeActor(String? value) {
  final normalized = value?.trim().toUpperCase().replaceAll('-', '_');
  if (normalized == null || normalized.isEmpty) {
    return RideChangeActor.unknown;
  }
  if (_driverActorValues.contains(normalized)) return RideChangeActor.driver;
  if (_passengerActorValues.contains(normalized)) {
    return RideChangeActor.passenger;
  }
  return RideChangeActor.unknown;
}

const _driverActorValues = {'DRIVER', 'DRIVER_APP', 'CHAUFFEUR', 'CONDUCTEUR'};

const _passengerActorValues = {
  'PASSENGER',
  'PASSENGER_APP',
  'PASSAGER',
  'CLIENT',
  'USER',
};

String? _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
