import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/address_formatter_service.dart';
import '../../core/utils/map_parsing_utils.dart';
import 'ride_status.dart';

class ActiveRide {
  static const _addressFormatter = AddressFormatterService();

  final String rideId;
  final String driverName;
  final String? driverPhone;
  final String driverPhoto;
  final double driverRating;
  final String carModel;
  final String carPlate;
  final String carColor;
  final String vehicleRange;
  final int driverRidesCount;
  final String? pickupPlaceId;
  final String? destinationPlaceId;
  final String? pickupAddress;
  final String? destinationAddress;
  final LatLng driverLocation;
  final LatLng? pickupLocation;
  final LatLng? destinationLocation;
  final RideStatus status;
  final DateTime? startTime;
  final DateTime? arrivedAt;
  final double estimatedPrice;
  final String? estimatedDuration;
  final String? estimatedDistance;
  const ActiveRide({
    required this.rideId,
    required this.driverName,
    this.driverPhone,
    required this.driverPhoto,
    required this.driverRating,
    required this.carModel,
    required this.carPlate,
    this.carColor = 'Non precisee',
    this.vehicleRange = 'MAGIC',
    this.driverRidesCount = 0,
    this.pickupPlaceId,
    this.destinationPlaceId,
    this.pickupAddress,
    this.destinationAddress,
    required this.driverLocation,
    this.pickupLocation,
    this.destinationLocation,
    required this.status,
    this.startTime,
    this.arrivedAt,
    required this.estimatedPrice,
    this.estimatedDuration,
    this.estimatedDistance,
  });

  ActiveRide copyWith({
    String? rideId,
    String? driverName,
    String? driverPhone,
    String? driverPhoto,
    double? driverRating,
    String? carModel,
    String? carPlate,
    String? carColor,
    String? vehicleRange,
    int? driverRidesCount,
    String? pickupPlaceId,
    String? destinationPlaceId,
    String? pickupAddress,
    String? destinationAddress,
    LatLng? driverLocation,
    LatLng? pickupLocation,
    LatLng? destinationLocation,
    RideStatus? status,
    DateTime? startTime,
    DateTime? arrivedAt,
    double? estimatedPrice,
    String? estimatedDuration,
    String? estimatedDistance,
  }) {
    return ActiveRide(
      rideId: rideId ?? this.rideId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      driverRating: driverRating ?? this.driverRating,
      carModel: carModel ?? this.carModel,
      carPlate: carPlate ?? this.carPlate,
      carColor: carColor ?? this.carColor,
      vehicleRange: vehicleRange ?? this.vehicleRange,
      driverRidesCount: driverRidesCount ?? this.driverRidesCount,
      pickupPlaceId: pickupPlaceId ?? this.pickupPlaceId,
      destinationPlaceId: destinationPlaceId ?? this.destinationPlaceId,
      pickupAddress: pickupAddress == null
          ? this.pickupAddress
          : _addressFormatter.normalize(pickupAddress),
      destinationAddress: destinationAddress == null
          ? this.destinationAddress
          : _addressFormatter.normalize(destinationAddress),
      driverLocation: driverLocation ?? this.driverLocation,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
    );
  }

  factory ActiveRide.fromMap(Map<String, dynamic> map) {
    final vehicle = nestedMap(map, ['vehicle', 'car', 'vehicule']);
    final driver =
        nestedMap(map, ['driver', 'conducteur', 'driverInfo', 'chauffeur']) ??
        nestedMap(vehicle ?? {}, ['sidUser']);
    final driverPosition = nestedMap(map, [
      'driverLocation',
      'currentDriverPosition',
    ]);
    final pickupAddress = firstString([
      map['departureAddress'],
      map['pickupAddress'],
      map['departure'],
    ], fallback: 'Lieu de départ');
    final destinationAddress = firstString([
      map['arrivalAddress'],
      map['destinationAddress'],
      map['arrival'],
    ], fallback: 'Destination');
    final driverPhone = firstString([
      driver?['phoneNumber'],
      driver?['phone'],
      driver?['telephone'],
      map['driverPhone'],
    ], fallback: '');
    final status = RideStatus.fromBackend(
      (map['statusRace'] ??
              map['status'] ??
              map['rideStatus'] ??
              map['courseStatus'] ??
              '')
          .toString(),
    );
    return ActiveRide(
      rideId: _rideId(map),
      driverName: firstString([
        _driverFullName(driver),
        driver?['fullName'],
        driver?['name'],
        map['driverName'],
      ], fallback: 'Chauffeur Fraya'),
      driverPhone: driverPhone.isEmpty ? null : driverPhone,
      driverPhoto: firstString([
        driver?['profilePhoto'],
        map['driverPhoto'],
      ], fallback: 'assets/images/driver_placeholder.png'),
      driverRating: _parseRating(driver?['rating'] ?? map['driverRating']),
      carModel: firstString([
        _buildCarModel(vehicle?['brand'], vehicle?['model']),
        vehicle?['model'],
        map['vehicleModel'],
      ], fallback: 'Véhicule Fraya'),
      carPlate: firstString([
        vehicle?['licensePlate'],
        vehicle?['plateNumber'],
        vehicle?['plate'],
        vehicle?['immatriculation'],
      ], fallback: '---'),
      carColor: firstString([
        vehicle?['color'],
        map['vehicleColor'],
        map['carColor'],
      ], fallback: 'Non precisee'),
      vehicleRange: firstString([
        map['requestedRange'],
        vehicle?['range'],
        map['vehicleRange'],
      ], fallback: 'MAGIC'),
      driverRidesCount:
          toInt(driver?['ridesCount'] ?? map['driverRidesCount']) ?? 0,
      pickupPlaceId: _extractPlaceId(
        map,
        directKeys: const ['departurePlaceId', 'pickupPlaceId', 'startPlaceId'],
        nestedKeys: const ['start', 'pickup', 'departure'],
      ),
      destinationPlaceId: _extractPlaceId(
        map,
        directKeys: const ['arrivalPlaceId', 'destinationPlaceId'],
        nestedKeys: const ['destination', 'arrival'],
      ),
      pickupAddress: _addressFormatter.normalize(pickupAddress),
      destinationAddress: _addressFormatter.normalize(destinationAddress),
      driverLocation: _driverLocation(map, driver, driverPosition),
      pickupLocation: parseLatLng(
        map,
        ['latDeparture', 'departureLat', 'lat_departure'],
        ['longDeparture', 'departureLng', 'lng_departure'],
      ),
      destinationLocation: parseLatLng(
        map,
        ['arrivalLat', 'latArrival', 'lat_arrival'],
        ['arrivalLong', 'longArrival', 'lng_arrival'],
      ),
      status: status,
      startTime: DateTime.tryParse(
        (map['departureDate'] ??
                map['startedAt'] ??
                map['updatedAt'] ??
                map['createdAt'] ??
                '')
            .toString(),
      ),
      arrivedAt: _arrivedAt(map, status),
      estimatedPrice:
          toDouble(
            map['finalPrice'] ?? map['estimatedPrice'] ?? map['price'],
          ) ??
          0,
      estimatedDuration: _durationValue(map),
      estimatedDistance: _distanceValue(map),
    );
  }
  static String _rideId(Map<String, dynamic> map) {
    return (map['id'] ??
            map['rideId'] ??
            map['courseId'] ??
            map['sidRace'] ??
            '')
        .toString();
  }

  static String? _driverFullName(Map<String, dynamic>? driver) {
    if (driver == null) return null;
    final first =
        (driver['firstNames'] ?? driver['firstName'])?.toString().trim() ?? '';
    final last = driver['lastName']?.toString().trim() ?? '';
    final fullName = '$first $last'.trim();
    return fullName.isEmpty ? null : fullName;
  }

  static LatLng _driverLocation(
    Map<String, dynamic> map,
    Map<String, dynamic>? driver,
    Map<String, dynamic>? driverPosition,
  ) {
    return parseLatLng(
      map,
      ['driverLat', 'driverLatitude', 'driver_location_lat'],
      ['driverLng', 'driverLongitude', 'driver_location_lng'],
      fallback: parseLatLng(
        driverPosition ?? driver ?? const <String, dynamic>{},
        ['lat', 'latitude'],
        ['lng', 'longitude'],
        fallback: const LatLng(5.3484, -4.0244),
      ),
    );
  }

  static String? _extractPlaceId(
    Map<String, dynamic> map, {
    required List<String> directKeys,
    required List<String> nestedKeys,
  }) {
    for (final key in directKeys) {
      final direct = firstString([map[key]], fallback: '').trim();
      if (direct.isNotEmpty) return direct;
    }

    for (final key in nestedKeys) {
      final nested = nestedMap(map, [key]);
      final nestedPlaceId = firstString([
        nested?['placeId'],
        nested?['place_id'],
      ], fallback: '').trim();
      if (nestedPlaceId.isNotEmpty) return nestedPlaceId;
    }

    return null;
  }

  static String? _durationValue(Map<String, dynamic> map) {
    final finalDuration = map['finalDuration'];
    if (finalDuration != null && finalDuration != 0 && finalDuration != '0') {
      return finalDuration.toString();
    }
    return map['estimatedDuration']?.toString();
  }

  static String? _distanceValue(Map<String, dynamic> map) {
    final finalDistance = map['finalDistance'];
    if (finalDistance != null && finalDistance != 0 && finalDistance != '0') {
      return finalDistance.toString();
    }
    return map['estimatedDistance']?.toString();
  }

  static double _parseRating(dynamic value) {
    final rating = toDouble(value);
    return rating != null && rating > 0 ? rating : 4.8;
  }

  static String? _buildCarModel(dynamic brand, dynamic model) {
    final safeBrand = brand?.toString().trim() ?? '';
    final safeModel = model?.toString().trim() ?? '';
    if (safeBrand.isEmpty && safeModel.isEmpty) return null;
    if (safeBrand.isEmpty || safeBrand == safeModel) {
      return safeModel.isEmpty ? null : safeModel;
    }
    return '$safeBrand $safeModel';
  }

  static DateTime? _arrivedAt(Map<String, dynamic> map, RideStatus status) {
    if (status != RideStatus.arrived) return null;
    for (final key in const [
      'driverArrivedAt',
      'arrivedAt',
      'arrivalAt',
      'dateDriverArrival',
      'dateArrival',
      'updatedAt',
    ]) {
      final raw = map[key];
      if (raw == null) continue;
      final parsed = DateTime.tryParse(raw.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static ActiveRide get mock => const ActiveRide(
    rideId: 'RIDE-123',
    driverName: 'Jean-Marc K.',
    driverPhone: '+2250700000000',
    driverPhoto: 'assets/images/driver_placeholder.png',
    driverRating: 4.8,
    carModel: 'Toyota Corolla (Gris)',
    carPlate: 'AB-123-CD',
    carColor: 'Gris',
    vehicleRange: 'MAGIC',
    driverLocation: LatLng(5.367, -3.984),
    status: RideStatus.accepted,
    estimatedPrice: 2500,
  );
}
