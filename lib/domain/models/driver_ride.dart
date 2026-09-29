import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/address_formatter_service.dart';
import '../../core/utils/map_parsing_utils.dart';
import 'ride_status.dart';
import 'driver_ride_parsing.dart';

class DriverRide {
  static const _addressFormatter = AddressFormatterService();
  const DriverRide({
    required this.rideId,
    required this.status,
    required this.passengerName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.requestedRange,
    required this.estimatedPrice,
    this.passengerPhone,
    this.passengerPhoto,
    this.passengerRating,
    this.passengerRidesCount,
    this.driverRatingFromPassenger,
    this.passengerCommentForDriver,
    this.finalPrice,
    this.commissionPrice,
    this.estimatedDistanceKm,
    this.estimatedDurationMin,
    this.assignedDriverId,
    this.vehicleId,
    this.driverLocation,
    this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.endedAt,
    this.completedAt,
    this.cancelledAt,
    this.keyRide,
  });

  final String rideId;
  final RideStatus status;
  final String passengerName;
  final String? passengerPhone;
  final String? passengerPhoto;
  final double? passengerRating;
  final int? passengerRidesCount;
  final double? driverRatingFromPassenger;
  final String? passengerCommentForDriver;
  String? get driverCommentFromPassenger => passengerCommentForDriver;
  final String pickupAddress;
  final String destinationAddress;
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String requestedRange;
  final double estimatedPrice;
  final double? finalPrice;
  final double? commissionPrice;
  final double? estimatedDistanceKm;
  final int? estimatedDurationMin;
  final int? assignedDriverId;
  final int? vehicleId;
  final LatLng? driverLocation;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? keyRide;
  DateTime? get historyDate {
    return (endedAt ?? startedAt ?? acceptedAt ?? updatedAt ?? createdAt)
        ?.toLocal();
  }

  DriverRide copyWith({
    String? rideId,
    RideStatus? status,
    String? passengerName,
    String? passengerPhone,
    Object? passengerPhoto = _sentinel,
    Object? passengerRating = _sentinel,
    Object? passengerRidesCount = _sentinel,
    Object? driverRatingFromPassenger = _sentinel,
    Object? passengerCommentForDriver = _sentinel,
    String? pickupAddress,
    String? destinationAddress,
    LatLng? pickupLocation,
    LatLng? destinationLocation,
    String? requestedRange,
    double? estimatedPrice,
    Object? finalPrice = _sentinel,
    Object? commissionPrice = _sentinel,
    Object? estimatedDistanceKm = _sentinel,
    Object? estimatedDurationMin = _sentinel,
    Object? assignedDriverId = _sentinel,
    Object? vehicleId = _sentinel,
    Object? driverLocation = _sentinel,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
    Object? acceptedAt = _sentinel,
    Object? arrivedAt = _sentinel,
    Object? startedAt = _sentinel,
    Object? endedAt = _sentinel,
    Object? completedAt = _sentinel,
    Object? cancelledAt = _sentinel,
    Object? keyRide = _sentinel,
  }) {
    return DriverRide(
      rideId: rideId ?? this.rideId,
      status: status ?? this.status,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      passengerPhoto: identical(passengerPhoto, _sentinel)
          ? this.passengerPhoto
          : passengerPhoto as String?,
      passengerRating: identical(passengerRating, _sentinel)
          ? this.passengerRating
          : passengerRating as double?,
      passengerRidesCount: identical(passengerRidesCount, _sentinel)
          ? this.passengerRidesCount
          : passengerRidesCount as int?,
      driverRatingFromPassenger: identical(driverRatingFromPassenger, _sentinel)
          ? this.driverRatingFromPassenger
          : driverRatingFromPassenger as double?,
      passengerCommentForDriver: identical(passengerCommentForDriver, _sentinel)
          ? this.passengerCommentForDriver
          : passengerCommentForDriver as String?,
      pickupAddress: pickupAddress == null
          ? this.pickupAddress
          : _addressFormatter.normalize(pickupAddress),
      destinationAddress: destinationAddress == null
          ? this.destinationAddress
          : _addressFormatter.normalize(destinationAddress),
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      requestedRange: requestedRange ?? this.requestedRange,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      finalPrice: identical(finalPrice, _sentinel)
          ? this.finalPrice
          : finalPrice as double?,
      commissionPrice: identical(commissionPrice, _sentinel)
          ? this.commissionPrice
          : commissionPrice as double?,
      estimatedDistanceKm: identical(estimatedDistanceKm, _sentinel)
          ? this.estimatedDistanceKm
          : estimatedDistanceKm as double?,
      estimatedDurationMin: identical(estimatedDurationMin, _sentinel)
          ? this.estimatedDurationMin
          : estimatedDurationMin as int?,
      assignedDriverId: identical(assignedDriverId, _sentinel)
          ? this.assignedDriverId
          : assignedDriverId as int?,
      vehicleId: identical(vehicleId, _sentinel)
          ? this.vehicleId
          : vehicleId as int?,
      driverLocation: identical(driverLocation, _sentinel)
          ? this.driverLocation
          : driverLocation as LatLng?,
      createdAt: identical(createdAt, _sentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _sentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
      acceptedAt: identical(acceptedAt, _sentinel)
          ? this.acceptedAt
          : acceptedAt as DateTime?,
      arrivedAt: identical(arrivedAt, _sentinel)
          ? this.arrivedAt
          : arrivedAt as DateTime?,
      startedAt: identical(startedAt, _sentinel)
          ? this.startedAt
          : startedAt as DateTime?,
      endedAt: identical(endedAt, _sentinel)
          ? this.endedAt
          : endedAt as DateTime?,
      completedAt: identical(completedAt, _sentinel)
          ? this.completedAt
          : completedAt as DateTime?,
      cancelledAt: identical(cancelledAt, _sentinel)
          ? this.cancelledAt
          : cancelledAt as DateTime?,
      keyRide: identical(keyRide, _sentinel)
          ? this.keyRide
          : keyRide as String?,
    );
  }

  factory DriverRide.fromMap(Map<String, dynamic> map) {
    final passenger =
        nestedMap(map, ['sidUser', 'user', 'passenger', 'customer']) ??
        const {};
    final driver = nestedMap(map, ['driver', 'chauffeur']) ?? const {};
    final vehicle = nestedMap(map, ['vehicle', 'vehicule']) ?? const {};
    final pickupAddress = _addressFormatter.normalize(
      firstString([
        map['departureAddress'],
        map['pickupAddress'],
        map['departure'],
      ], fallback: 'Lieu de départ'),
    );
    final destinationAddress = _addressFormatter.normalize(
      firstString([
        map['arrivalAddress'],
        map['destinationAddress'],
        map['arrival'],
      ], fallback: 'Destination'),
    );
    final status = RideStatus.fromBackend(
      firstNonEmptyDriverRideValue([
        map['statusRace'],
        map['status'],
        map['rideStatus'],
      ]),
    );
    final acceptedAt = parseDriverRideDate(
      map['dateAcceptance'] ?? map['acceptedAt'],
    );
    final rawDateArrival = parseDriverRideDate(map['dateArrival']);
    final arrivedAt =
        parseDriverRideDate(
          map['driverArrivedAt'] ??
              map['arrivedAt'] ??
              map['dateDriverArrival'] ??
              map['dateArrived'],
        ) ??
        switch (status) {
          RideStatus.arrived || RideStatus.inProgress => rawDateArrival,
          _ => null,
        };
    final startedAt = parseDriverRideDate(
      map['departureDate'] ?? map['startedAt'],
    );
    final completedAt =
        parseDriverRideDate(map['completedAt'] ?? map['finishedAt']) ??
        (status == RideStatus.completed ? rawDateArrival : null);
    final cancelledAt = parseDriverRideDate(
      map['dateCancellation'] ?? map['cancelledAt'] ?? map['canceledAt'],
    );
    final endedAt = switch (status) {
      RideStatus.completed => completedAt,
      RideStatus.cancelled => cancelledAt,
      _ => completedAt ?? cancelledAt,
    };

    return DriverRide(
      rideId: firstNonEmptyDriverRideValue([
        map['id'],
        map['rideId'],
        map['courseId'],
      ]),
      status: status,
      passengerName: firstString([
        fullNameFromDriverRideUser(passenger),
        passenger['name'],
        passenger['fullName'],
        map['passengerName'],
      ], fallback: 'Passager'),
      passengerPhone: optionalDriverRideString([
        passenger['phoneNumber'],
        passenger['phone'],
        passenger['telephone'],
        map['passengerPhone'],
      ]),
      passengerPhoto: optionalDriverRideString([
        passenger['profilePhoto'],
        passenger['photo'],
        passenger['avatar'],
        passenger['image'],
        map['passengerPhoto'],
      ]),
      passengerRating: toDouble(
        passenger['rating'] ?? map['passengerRating'] ?? map['userRating'],
      ),
      passengerRidesCount: toInt(
        passenger['coursesCount'] ??
            passenger['ridesCount'] ??
            map['passengerCoursesCount'] ??
            map['passengerRidesCount'],
      ),
      driverRatingFromPassenger: toDouble(map['driverRating']),
      passengerCommentForDriver: optionalDriverRideString([
        map['commentDriver'],
      ]),
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      pickupLocation: parseLatLng(
        map,
        const ['latDeparture', 'pickupLat', 'departureLat'],
        const ['longDeparture', 'pickupLng', 'departureLng'],
      ),
      destinationLocation: parseLatLng(
        map,
        const ['arrivalLat', 'destinationLat'],
        const ['arrivalLong', 'destinationLng'],
      ),
      requestedRange: firstString([
        map['requestedRange'],
        vehicle['range'],
      ], fallback: 'MAGIC'),
      estimatedPrice:
          toDouble(
            map['estimatedPrice'] ?? map['price'] ?? map['finalPrice'],
          ) ??
          0,
      finalPrice: toDouble(map['finalPrice']),
      commissionPrice: toDouble(map['commissionPrice']),
      estimatedDistanceKm: toDouble(
        map['estimatedDistance'] ??
            map['finalDistance'] ??
            map['finalDistanceKm'],
      ),
      estimatedDurationMin: toInt(
        map['estimatedDuration'] ??
            map['finalDuration'] ??
            map['finalDurationMin'],
      ),
      assignedDriverId: extractDriverRideDriverId(map, driver, vehicle),
      vehicleId: toInt(vehicle['id'] ?? map['vehicleId']),
      driverLocation: parseDriverRideDriverLocation(map, driver),
      createdAt: parseDriverRideDate(map['createdAt'] ?? map['requestedAt']),
      updatedAt: parseDriverRideDate(map['updatedAt']),
      acceptedAt: acceptedAt,
      arrivedAt: arrivedAt,
      startedAt: startedAt,
      endedAt: endedAt,
      completedAt: completedAt,
      cancelledAt: cancelledAt,
      keyRide: optionalDriverRideString([map['keyRide']]),
    );
  }
  bool get isPending => status == RideStatus.pending;
  bool get isActiveForDriver =>
      status == RideStatus.accepted ||
      status == RideStatus.arrived ||
      status == RideStatus.inProgress;
}

const Object _sentinel = Object();
