library;

import '../../core/error/exceptions.dart';
import '../../core/models/ride_category.dart';
import '../../core/utils/logger.dart';
import '../../domain/models/active_ride.dart';
import '../../domain/models/ride_share_link.dart';
import '../../domain/models/ride_status.dart';
import '../../domain/repositories/booking_repository.dart';
import '../sources/remote/booking_remote_data_source.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({required BookingRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final BookingRemoteDataSource _remoteDataSource;

  @override
  Future<List<RideCategory>> getRideCategories() async {
    final List<dynamic> data = await _remoteDataSource.getRangePricing();
    return data
        .map<RideCategory>(
          (e) => RideCategory.fromBackendApi(e as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<Map<String, RidePriceEstimate>> calculateRidePrices(
    CalculateRidePricesParams params,
  ) async {
    final response = await _remoteDataSource.calculatePrices(params);
    logger.debug('calculateRidePrices response: success=${response['success']} dataType=${response['data']?.runtimeType} data=${response['data']}');
    if (response['success'] != true || response['data'] == null) {
      logger.warning('calculateRidePrices: success=${response['success']}, data=${response['data']}');
      return const {};
    }
    return _extractPricesByRange(response['data']);
  }

  @override
  Future<int?> calculateRidePrice(CalculateRidePriceParams params) async {
    final prices = await calculateRidePrices(
      CalculateRidePricesParams(
        latDeparture: params.latDeparture,
        longDeparture: params.longDeparture,
        arrivalPlaceId: params.arrivalPlaceId,
        arrivalLat: params.arrivalLat,
        arrivalLong: params.arrivalLong,
        stops: params.stops,
        promoCode: params.promoCode,
        waitingSeconds: params.waitingSeconds,
      ),
    );
    return prices[params.range]?.totalPrice;
  }

  @override
  Future<String> requestRide(RequestRideParams params) async {
    final response = await _remoteDataSource.requestRide(params);
    return _extractRideIdFromResponse(response);
  }

  @override
  Future<bool> cancelRide(String rideId, {String? reason}) {
    return _remoteDataSource.cancelRide(rideId, reason: reason);
  }

  @override
  Future<List<Map<String, dynamic>>> getUserRides(int userId) {
    return _remoteDataSource.getUserRides(userId);
  }

  @override
  Future<ActiveRide?> getActiveRide(
    int userId, {
    String? rideId,
  }) async {
    final rides = await getUserRides(userId);

    if (rideId != null && rideId.isNotEmpty) {
      final selectedRide = _findRideById(rides, rideId);
      if (selectedRide == null) return null;
      return ActiveRide.fromMap(await _enrichWithDriverGps(selectedRide));
    }

    final activeRide = _findLatestActiveRide(rides);
    if (activeRide != null) {
      return ActiveRide.fromMap(await _enrichWithDriverGps(activeRide));
    }

    final fallbackData = await _getActiveRideFromEndpoint(userId);
    if (fallbackData != null) {
      return ActiveRide.fromMap(await _enrichWithDriverGps(fallbackData));
    }

    return null;
  }

  @override
  Future<RideShareLink> createRideShareLink({
    required String rideId,
    int expiresIn = 60,
  }) {
    return _remoteDataSource.createRideShareLink(
      rideId: rideId,
      expiresIn: expiresIn,
    );
  }

  @override
  Future<RateRideOutcome> rateRide({
    required String rideId,
    required int rating,
    String? comment,
    double? tip,
  }) async {
    return _remoteDataSource.rateRide(
      rideId: rideId,
      rating: rating,
      comment: comment,
      tip: tip,
    );
  }

  @override
  Future<bool> triggerSos({
    required String rideId,
    required int userId,
    required double lat,
    required double lng,
    String? notes,
  }) {
    return _remoteDataSource.triggerSos(
      rideId: rideId,
      userId: userId,
      lat: lat,
      lng: lng,
      notes: notes,
    );
  }

  @override
  Future<bool> createSupportTicket({
    required String rideId,
    required int userId,
    required String category,
    String? description,
  }) {
    return _remoteDataSource.createSupportTicket(
      rideId: rideId,
      userId: userId,
      category: category,
      description: description,
    );
  }

  Future<Map<String, dynamic>> _enrichWithDriverGps(
    Map<String, dynamic> rideMap,
  ) async {
    try {
      final driverId = _extractDriverId(rideMap);
      if (driverId == null) return rideMap;
      final nearbyDrivers = await _remoteDataSource.getNearbyDrivers();
      final driverGps = nearbyDrivers.firstWhere(
        (d) => d['id']?.toString() == driverId,
        orElse: () => {},
      );
      if (driverGps.isEmpty) return rideMap;
      return {
        ...rideMap,
        'driverLat': driverGps['latitude'],
        'driverLng': driverGps['longitude'],
      };
    } catch (_) {
      return rideMap;
    }
  }

  String? _extractDriverId(Map<String, dynamic> ride) {
    final vehicle = ride['vehicle'];
    if (vehicle is! Map) return null;
    final sidUserId = vehicle['sidUserId'];
    if (sidUserId != null) return sidUserId.toString();
    final sidUser = vehicle['sidUser'];
    if (sidUser is Map) return sidUser['id']?.toString();
    return null;
  }

  Future<Map<String, dynamic>?> _getActiveRideFromEndpoint(int userId) async {
    try {
      return await _remoteDataSource.getActiveRide(userId);
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ServerException {
      return null;
    }
  }

  Map<String, RidePriceEstimate> _extractPricesByRange(dynamic data) {
    if (data is! Map) {
      logger.warning('_extractPricesByRange: data is not a Map (type=${data?.runtimeType})');
      return const {};
    }

    final outerMap = Map<String, dynamic>.from(data);
    logger.debug('_extractPricesByRange outerMap keys: ${outerMap.keys.toList()}');

    // L'API peut retourner { "prices": [...] } ou { "data": { "prices": [...] } }.
    final rawPrices = outerMap['prices'] ?? (outerMap['data'] as Map?)?['prices'];
    if (rawPrices is! List) {
      logger.warning('_extractPricesByRange: prices not found or not a List. outerMap=$outerMap');
      return const {};
    }

    final pricesByRange = <String, RidePriceEstimate>{};
    for (final item in rawPrices) {
      if (item is! Map) continue;
      final entry = Map<String, dynamic>.from(item);
      final range = entry['range']?.toString();
      if (range == null || range.isEmpty) continue;
      final totalPrice = _readInt(entry['totalPrice']);
      if (totalPrice == null) continue;
      final amountReceived =
          _readInt(entry['amountReceved'] ?? entry['amountReceived']) ??
          totalPrice;
      pricesByRange[range] = RidePriceEstimate(
        range: range,
        totalPrice: totalPrice,
        amountReceived: amountReceived,
      );
    }
    logger.debug('_extractPricesByRange result: $pricesByRange');
    return pricesByRange;
  }

  int? _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic>? _findRideById(
    List<Map<String, dynamic>> rides,
    String rideId,
  ) {
    for (final ride in rides) {
      if (_extractId(ride) == rideId) {
        return ride;
      }
    }
    return null;
  }

  Map<String, dynamic>? _findLatestActiveRide(List<Map<String, dynamic>> rides) {
    final activeRides = rides.where(_isActiveRide).toList();
    if (activeRides.isEmpty) {
      return null;
    }
    activeRides.sort(_compareRideRecency);
    return activeRides.first;
  }

  bool _isActiveRide(Map<String, dynamic> ride) {
    final status = ActiveRide.fromMap(ride).status;
    return status != RideStatus.completed && status != RideStatus.cancelled;
  }

  int _compareRideRecency(Map<String, dynamic> left, Map<String, dynamic> right) {
    return _readRideDate(right).compareTo(_readRideDate(left));
  }

  DateTime _readRideDate(Map<String, dynamic> ride) {
    return DateTime.tryParse(
          (ride['updatedAt'] ?? ride['createdAt'] ?? '').toString(),
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _extractId(Map<String, dynamic> ride) {
    return (ride['id'] ?? ride['rideId'] ?? ride['courseId'] ?? '').toString();
  }

  String _extractRideIdFromResponse(Map<String, dynamic> response) {
    dynamic current = response;
    while (current is Map &&
        current.length <= 3 &&
        (current.containsKey('data') || current.containsKey('result'))) {
      current = current['data'] ?? current['result'];
    }
    if (current is Map) {
      final id = current['id'] ?? current['rideId'] ?? current['courseId'];
      if (id != null && id.toString().isNotEmpty) {
        return id.toString();
      }
    }
    return '';
  }
}
