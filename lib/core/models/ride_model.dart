import 'package:flutter/material.dart';
import '../services/address_formatter_service.dart';
import '../../core/theme/app_colors.dart';

enum RideStatus {
  pending,
  accepted,
  ongoing,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case RideStatus.pending:
        return 'En attente';
      case RideStatus.accepted:
        return 'Acceptée';
      case RideStatus.ongoing:
        return 'En cours';
      case RideStatus.completed:
        return 'Terminée';
      case RideStatus.cancelled:
        return 'Annulée';
    }
  }

  Color get color {
    switch (this) {
      case RideStatus.pending:
        return AppColors.warning;
      case RideStatus.accepted:
        return AppColors.info;
      case RideStatus.ongoing:
        return AppColors.success;
      case RideStatus.completed:
        return AppColors.success;
      case RideStatus.cancelled:
        return AppColors.error;
    }
  }
}

class Ride {
  static const _addressFormatter = AddressFormatterService();

  final String id;
  final String departureAddress;
  final String arrivalAddress;
  final String? departurePlaceId;
  final String? arrivalPlaceId;
  final double departureLat;
  final double departureLng;
  final double arrivalLat;
  final double arrivalLng;
  final int price;
  final DateTime date;
  final RideStatus status;
  final String? keyRide;
  final String? duration;
  final String? distance;

  // Driver Info
  final String? driverName;

  /// Note donnee par le chauffeur au passager pour CETTE course
  /// (champ `passengerRating` de la course).
  final double? passengerRatingFromDriver;

  /// Commentaire donne par le chauffeur au passager pour CETTE course
  /// (champ `passengerComment` de la course).
  final String? passengerCommentFromDriver;

  /// Note donnee par le passager au chauffeur pour CETTE course
  /// (champ `driverRating` de la course ; 0/null = pas encore notee).
  final double? driverRatingFromPassenger;

  /// Commentaire donne par le passager au chauffeur pour CETTE course
  /// (champ `commentDriver` de la course).
  final String? driverCommentFromPassenger;

  /// Moyenne/note de profil du chauffeur (champ `rating` du chauffeur).
  /// Souvent `null` tant que le backend ne l'expose pas dans le payload course.
  final double? driverProfileRating;
  final String? driverPhoto;
  final int? driverRidesCount;
  final bool isDriverVerified;

  // Vehicle Info
  final String vehicleRange;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? licensePlate;

  // Payment Info
  final String? paymentMethod;
  final String? transactionId;

  // Contact & History
  final String? driverPhone;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? completedAt;

  Ride({
    required this.id,
    required this.departureAddress,
    required this.arrivalAddress,
    this.keyRide,
    this.departurePlaceId,
    this.arrivalPlaceId,
    this.departureLat = 5.3484,
    this.departureLng = -3.9554,
    this.arrivalLat = 5.3265,
    this.arrivalLng = -4.0198,
    required this.price,
    required this.date,
    required this.status,
    this.duration,
    this.distance,
    this.driverName,
    this.passengerRatingFromDriver,
    this.passengerCommentFromDriver,
    this.driverRatingFromPassenger,
    String? driverCommentFromPassenger,
    @Deprecated('Use driverCommentFromPassenger instead')
    String? driverCommentForDriver,
    this.driverProfileRating,
    this.driverPhoto,
    this.driverRidesCount,
    this.isDriverVerified = false,
    required this.vehicleRange,
    this.vehicleModel,
    this.vehicleColor,
    this.licensePlate,
    this.paymentMethod,
    this.transactionId,
    this.driverPhone,
    this.acceptedAt,
    this.startedAt,
    this.endedAt,
    this.completedAt,
  }) : driverCommentFromPassenger =
           driverCommentFromPassenger ?? driverCommentForDriver;

  /// `true` si la course est terminée et que le passager n'a pas encore noté
  /// le chauffeur (note de course absente ou <= 0).
  bool get canRateDriver =>
      status == RideStatus.completed &&
      (driverRatingFromPassenger == null || driverRatingFromPassenger! <= 0) &&
      (driverCommentFromPassenger == null ||
          driverCommentFromPassenger!.trim().isEmpty);

  /// `true` si le passager a déjà noté le chauffeur pour cette course.
  bool get hasRated =>
      driverRatingFromPassenger != null && driverRatingFromPassenger! > 0;

  @Deprecated('Use driverRatingFromPassenger instead')
  double? get driverRideRating => driverRatingFromPassenger;

  @Deprecated('Use driverCommentFromPassenger instead')
  String? get ratingComment => driverCommentFromPassenger;

  @Deprecated('Use driverCommentFromPassenger instead')
  String? get commentDriver => driverCommentFromPassenger;

  @Deprecated('Use driverCommentFromPassenger instead')
  String? get driverCommentForDriver => driverCommentFromPassenger;

  factory Ride.fromMap(Map<String, dynamic> map) {
    // Support des champs driver imbriqués de manière tolérante
    final vehicle = _nestedMap(map, ['vehicle', 'car', 'vehicule']);
    final driver =
        _nestedMap(map, ['driver', 'driverInfo', 'chauffeur']) ??
        _nestedMap(vehicle ?? {}, ['sidUser']) ??
        _nestedMap(map, ['sidUser']);

    // Support des deux conventions de nommage (latDeparture vs departureLat)
    final double depLat =
        _toDouble(map['departureLat'] ?? map['latDeparture'] ?? map['lat']) ??
        5.3484;
    final double depLng =
        _toDouble(map['departureLng'] ?? map['longDeparture'] ?? map['lng']) ??
        -3.9554;
    final double arrLat =
        _toDouble(map['arrivalLat'] ?? map['latArrival']) ?? 5.3265;
    final double arrLng =
        _toDouble(map['arrivalLng'] ?? map['longArrival']) ?? -4.0198;

    // Prix : finalPrice en priorité, sinon estimatedPrice
    final int price =
        _toDouble(
          map['finalPrice'] ?? map['estimatedPrice'] ?? map['price'],
        )?.toInt() ??
        0;
    final status = _parseStatus(
      (map['status'] ??
              map['rideStatus'] ??
              map['courseStatus'] ??
              map['statusRace'] ??
              '')
          .toString(),
    );
    final acceptedAt = _parseDate(map['dateAcceptance'] ?? map['acceptedAt']);
    final startedAt = _parseDate(
      map['departureDate'] ?? map['startedAt'] ?? map['pickupAt'],
    );
    final completedAt = _parseDate(
      map['dateArrival'] ?? map['completedAt'] ?? map['finishedAt'],
    );
    final cancelledAt = _parseDate(
      map['dateCancellation'] ?? map['cancelledAt'] ?? map['canceledAt'],
    );
    final endedAt = switch (status) {
      RideStatus.completed => completedAt,
      RideStatus.cancelled => cancelledAt,
      _ => completedAt ?? cancelledAt,
    };
    final createdAt = _parseDate(map['createdAt']);
    final legacyDate = _parseDate(map['date']);
    final date =
        endedAt ??
        startedAt ??
        acceptedAt ??
        createdAt ??
        legacyDate ??
        DateTime.now();

    // Nom du chauffeur (tolérant)
    final String? driverName = _firstNonEmpty([
      driver?['name'],
      driver?['fullName'],
      (driver?['firstNames'] != null || driver?['lastName'] != null)
          ? '${driver?['firstNames'] ?? ''} ${driver?['lastName'] ?? ''}'.trim()
          : null,
      map['driverName'],
    ]);

    return Ride(
      id: (map['id'] ?? map['rideId'] ?? map['courseId'] ?? '').toString(),
      departureAddress: _addressFormatter.normalize(
        (map['departureAddress'] ?? map['departure'] ?? '').toString(),
      ),
      arrivalAddress: _addressFormatter.normalize(
        (map['arrivalAddress'] ?? map['arrival'] ?? '').toString(),
      ),
      departurePlaceId: _extractPlaceId(
        map,
        topLevelKey: 'departurePlaceId',
        nestedKey: 'start',
      ),
      arrivalPlaceId: _extractPlaceId(
        map,
        topLevelKey: 'arrivalPlaceId',
        nestedKey: 'destination',
      ),
      departureLat: depLat,
      departureLng: depLng,
      arrivalLat: arrLat,
      arrivalLng: arrLng,
      price: price,
      date: date,
      status: status,
      duration: map['estimatedDuration']?.toString() ?? map['duration'],
      distance: map['estimatedDistance']?.toString() ?? map['distance'],
      driverName: driverName,
      passengerRatingFromDriver: _toDouble(
        map['passagerRating'] ?? map['passengerRating'],
      ),
      passengerCommentFromDriver: _firstNonEmpty([
        map['passagerComment'],
        map['passengerComment'],
      ]),
      driverRatingFromPassenger: _toDouble(map['driverRating']),
      driverCommentFromPassenger: _firstNonEmpty([map['commentDriver']]),
      driverProfileRating: _toDouble(driver?['rating']),
      driverPhoto: _firstNonEmpty([
        driver?['photo'],
        driver?['profilePhoto'],
        driver?['avatar'],
        map['driverPhoto'],
      ]),
      driverRidesCount: _toInt(
        driver?['coursesCount'] ??
            driver?['ridesCount'] ??
            map['driverRidesCount'],
      ),
      isDriverVerified: driver?['isVerified'] ?? false,
      vehicleRange: (map['requestedRange'] ?? map['vehicleRange'] ?? 'MAGIC')
          .toString(),
      vehicleModel: _firstNonEmpty([
        vehicle?['model'],
        vehicle?['brand'] != null
            ? '${vehicle?['brand'] ?? ''} ${vehicle?['model'] ?? ''}'.trim()
            : null,
        map['vehicleModel'],
      ]),
      vehicleColor: _firstNonEmpty([vehicle?['color'], map['vehicleColor']]),
      licensePlate: _firstNonEmpty([
        vehicle?['licensePlate'],
        vehicle?['plate'],
        map['licensePlate'],
      ]),
      paymentMethod:
          (map['payment']?['method'] ??
                  map['paymentMethod'] ??
                  map['paymentMode'])
              ?.toString(),
      transactionId: (map['payment']?['transactionId'] ?? map['transactionId'])
          ?.toString(),
      driverPhone: _firstNonEmpty([
        driver?['phoneNumber'],
        driver?['phone'],
        driver?['telephone'],
        map['driverPhone'],
      ]),
      acceptedAt: acceptedAt,
      startedAt: startedAt,
      endedAt: endedAt,
      completedAt: completedAt,
      keyRide: map['keyRide']?.toString(),
    );
  }

  static RideStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
      case 'REQUESTED':
      case 'SEARCHING':
      case 'SEARCHING_DRIVER':
        return RideStatus.pending;
      case 'ACCEPTED':
      case 'ASSIGNED':
      case 'DRIVER_ASSIGNED':
        return RideStatus.accepted;
      case 'ONGOING':
      case 'STARTED':
      case 'IN_PROGRESS':
      case 'ARRIVED':
      case 'DRIVER_ARRIVED':
      case 'WAITING_FOR_PASSENGER':
      case 'ON_TRIP':
      case 'PICKED_UP':
        return RideStatus.ongoing;
      case 'COMPLETED':
      case 'FINISHED':
        return RideStatus.completed;
      case 'CANCELLED':
      case 'CANCELED':
      case 'CANCELLED_PASSENGER':
      case 'CANCELLED_DRIVER':
        return RideStatus.cancelled;
      default:
        return RideStatus.completed;
    }
  }

  static Map<String, dynamic>? _nestedMap(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static String? _extractPlaceId(
    Map<String, dynamic> source, {
    required String topLevelKey,
    required String nestedKey,
  }) {
    final direct = _firstNonEmpty([
      source[topLevelKey],
      source['${nestedKey}PlaceId'],
    ]);
    if (direct != null) return direct;
    final nested = _nestedMap(source, [nestedKey]);
    return _firstNonEmpty([nested?['placeId'], nested?['place_id']]);
  }
}
