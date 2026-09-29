library;

class PushNotificationPayload {
  const PushNotificationPayload({
    this.type,
    this.title,
    this.body,
    this.rawData,
    this.rideId,
    this.driverId,
    this.recipientRole,
    this.rating,
    this.finalPrice,
    this.cancelledBy,
    this.latitude,
    this.longitude,
    this.notificationId,
  });

  final String? type;
  final String? title;
  final String? body;
  final Map<String, dynamic>? rawData;
  final String? rideId;
  final String? driverId;
  final String? recipientRole;
  final int? rating;
  final double? finalPrice;
  final String? cancelledBy;
  final double? latitude;
  final double? longitude;
  final String? notificationId;

  bool get isSupported => supportedTypes.contains(type);

  static const supportedTypes = {
    'new_ride_available',
    'ride_accepted',
    'ride_cancelled',
    'ride_started',
    'ride_completed',
    'driver_arrived',
    'driver_rated',
    'drivers_nearby',
  };

  factory PushNotificationPayload.fromData({
    String? title,
    String? body,
    Map<String, dynamic>? rawData,
  }) {
    final data = _extractData(rawData);
    final type = _normalizeType(
      _firstNonEmpty([data['type'], rawData?['pushType']]),
    );
    return PushNotificationPayload(
      type: type,
      title: title?.trim(),
      body: body?.trim(),
      rawData: rawData,
      rideId: _firstNonEmpty([data['rideId'], data['id'], data['courseId']]),
      driverId: _firstNonEmpty([
        data['driverId'],
        data['driver_id'],
        data['sidUserId'],
      ]),
      recipientRole: _firstNonEmpty([
        data['recipientRole'],
        data['role'],
      ])?.toUpperCase(),
      rating: _toInt(data['rating']),
      finalPrice: _toDouble(data['finalPrice'] ?? data['amountReceived']),
      cancelledBy: _firstNonEmpty([
        data['cancelledBy'],
        data['canceledBy'],
        data['changedBy'],
        data['source'],
        data['by'],
        data['actor'],
      ]),
      latitude: _toDouble(data['latitude'] ?? data['lat']),
      longitude: _toDouble(data['longitude'] ?? data['lng'] ?? data['long']),
      notificationId: _firstNonEmpty([
        rawData?['notificationId'],
        data['notificationId'],
      ]),
    );
  }
}

Map<String, dynamic> _extractData(Map<String, dynamic>? rawData) {
  final data = <String, dynamic>{};
  if (rawData != null) data.addAll(rawData);
  final nested = rawData?['data'];
  if (nested is Map<String, dynamic>) {
    data.addAll(nested);
  } else if (nested is Map) {
    data.addAll(Map<String, dynamic>.from(nested));
  }
  return data;
}

String? _normalizeType(String? value) {
  final text = value?.trim().toLowerCase();
  return text == null || text.isEmpty ? null : text;
}

String? _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
