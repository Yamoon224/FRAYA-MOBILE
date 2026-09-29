library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../sources/api_client.dart';

class DriverRideRemoteDataSource {
  DriverRideRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getAllRides() async {
    try {
      final response = await _dio.get('/rides/maps');
      return _extractRides(response: response);
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible de charger les courses chauffeur : $error',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableRides({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    try {
      final response = await _dio.get(
        '/rides/maps/available',
        queryParameters: {'lat': lat, 'lng': lng, 'radius': radiusKm},
      );
      return _extractRides(response: response);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 400 || statusCode == 404) {
        return getAllRides();
      }
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible de charger les courses disponibles : $error',
      );
    }
  }

  Future<void> acceptRide(
    String rideId, {
    required int driverId,
    required int vehicleId,
  }) async {
    await _postDriverAction(
      '/rides/maps/$rideId/accept',
      data: {
        'rideId': int.tryParse(rideId) ?? rideId,
        'driverId': driverId,
        'vehicleId': vehicleId,
      },
      conflictMessageResolver: _resolveAcceptConflictMessage,
    );
  }

  Future<Map<String, dynamic>?> getActiveRideForDriver(int driverId) async {
    try {
      final response = await _dio.get('/rides/maps/driver/$driverId/active');
      final rides = _extractRides(response: response);
      return rides.isNotEmpty ? rides.first : null;
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible de charger la course active : $error',
      );
    }
  }

  Future<void> markArrived(
    String rideId, {
    required double driverLat,
    required double driverLng,
  }) async {
    await _postDriverAction(
      '/rides/maps/$rideId/arrived',
      data: {
        'rideId': int.tryParse(rideId) ?? rideId,
        'driverLat': driverLat.toString(),
        'driverLng': driverLng.toString(),
      },
    );
  }

  Future<void> startRide(String rideId) async {
    await _postDriverAction(
      '/rides/maps/$rideId/start',
      data: {'rideId': int.tryParse(rideId) ?? rideId},
    );
  }

  Future<void> completeRide(
    String rideId, {
    required double finalDistanceKm,
    required int finalDurationMin,
    required int finalPrice,
    required int additionnalFreeSeconds,
  }) async {
    await _postDriverAction(
      '/rides/maps/$rideId/complete',
      data: {
        'rideId': int.tryParse(rideId) ?? rideId,
        'finalDistanceKm': finalDistanceKm.toString(),
        'finalDurationMin': finalDurationMin.toString(),
        'finalPrice': finalPrice.toString(),
        'additionnalFree': additionnalFreeSeconds,
      },
    );
  }

  Future<void> cancelRide(String rideId, {String? reason}) async {
    await _postDriverAction(
      '/rides/maps/$rideId/cancel',
      data: {
        'by': 'DRIVER',
        'rideId': int.tryParse(rideId) ?? rideId,
        'reason': reason ?? 'Annulation chauffeur',
      },
    );
  }

  Future<void> _postDriverAction(
    String path, {
    required Map<String, dynamic> data,
    String? conflictMessage,
    String Function(Response<dynamic>?, int?)? conflictMessageResolver,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          _isBusinessSuccess(response.data)) {
        return;
      }

      final businessStatusCode = _extractBusinessStatusCode(response.data);
      final businessMessage = _extractBusinessMessage(response.data);
      throw ServerException(
        message: businessMessage,
        statusCode: businessStatusCode ?? response.statusCode,
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final backendMessage = _extractMessage(error.response);
      if (statusCode == 403 || statusCode == 409) {
        final resolvedConflictMessage =
            conflictMessageResolver?.call(error.response, statusCode) ??
            conflictMessage ??
            backendMessage;
        throw ServerException(
          message: resolvedConflictMessage,
          statusCode: statusCode,
        );
      }
      if (statusCode != null && statusCode >= 500) {
        throw ServerException(
          message:
              'Erreur backend (HTTP $statusCode): ${_extractMessage(error.response)}',
          statusCode: statusCode,
        );
      }
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: 'Impossible d\'executer l\'action chauffeur : $error',
      );
    }
  }

  List<Map<String, dynamic>> _extractRideList(dynamic data) {
    final unwrapped = _unwrapData(data);
    if (unwrapped is List) {
      return unwrapped
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (unwrapped is Map) {
      final map = Map<String, dynamic>.from(unwrapped);
      for (final key in ['data', 'rides', 'courses', 'items', 'results']) {
        final value = map[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
      return [map];
    }
    return const [];
  }

  List<Map<String, dynamic>> _extractRides({
    required Response<dynamic> response,
  }) {
    return _extractRideList(response.data);
  }

  dynamic _unwrapData(dynamic data) {
    var current = data;
    while (current is Map &&
        (current.containsKey('data') || current.containsKey('result'))) {
      final next = current['data'] ?? current['result'];
      if (next == null || identical(next, current)) {
        break;
      }
      current = next;
    }
    return current;
  }

  String _extractMessage(Response<dynamic>? response) {
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    return 'Action chauffeur indisponible pour le moment.';
  }

  bool _isBusinessSuccess(dynamic payload) {
    if (payload is! Map) {
      return true;
    }
    final map = Map<String, dynamic>.from(payload);
    final success = map['success'];
    if (success is bool) {
      return success;
    }
    return true;
  }

  int? _extractBusinessStatusCode(dynamic payload) {
    if (payload is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(payload);
    final raw = map['statusCode'];
    if (raw is int) {
      return raw;
    }
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }

  String _extractBusinessMessage(dynamic payload) {
    if (payload is! Map) {
      return 'Reponse serveur inattendue pour l\'action chauffeur.';
    }
    final map = Map<String, dynamic>.from(payload);
    final message = map['message'] ?? map['error'];
    final text = message?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
    return 'Reponse serveur inattendue pour l\'action chauffeur.';
  }

  String _resolveAcceptConflictMessage(
    Response<dynamic>? response,
    int? statusCode,
  ) {
    final rawMessage = _extractMessage(response);
    final normalized = rawMessage.toLowerCase();

    if (_containsAny(normalized, _cancelledKeywords)) {
      return 'Cette course a été annulée entre-temps.';
    }
    if (_containsAny(normalized, _alreadyAssignedKeywords)) {
      return 'Cette course a déjà été attribuée à un autre chauffeur.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Erreur backend (HTTP $statusCode): $rawMessage';
    }
    return 'Cette course n\'est plus disponible. $rawMessage';
  }

  bool _containsAny(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  static const List<String> _cancelledKeywords = <String>[
    'cancel',
    'annul',
    'annulee',
    'annule',
  ];

  static const List<String> _alreadyAssignedKeywords = <String>[
    'already assigned',
    'already taken',
    'already accepted',
    'another driver',
    'other driver',
    'deja assigne',
    'deja attribue',
    'assigne',
    'attribue',
    'taken',
  ];

  Future<void> sendDriverLocation({
    required String rideId,
    required int driverId,
    required double lat,
    required double lng,
  }) async {
    final path = '/rides/maps/$rideId/positions';
    final payload = {
      'driverId': driverId,
      'latitude': lat,
      'longitude': lng,
      'timestamp': DateTime.now().toIso8601String(),
    };
    try {
      logger.debug('sendDriverLocation request: path=$path payload=$payload');
      final response = await _dio.post(path, data: payload);
      logger.debug(
        'sendDriverLocation response: status=${response.statusCode} data=${response.data}',
      );
    } catch (error, stackTrace) {
      logger.warning('sendDriverLocation failed', error, stackTrace);
      // fire-and-forget : les erreurs réseau ne bloquent pas l'UX
    }
  }

  Future<void> sendDriverAvailabilityLocation({
    required double lat,
    required double lng,
  }) async {
    const path = '/rides/maps/drivers/location';
    final payload = {
      'latitude': lat,
      'longitude': lng,
      'timestamp': DateTime.now().toIso8601String(),
    };
    try {
      logger.debug(
        'sendDriverAvailabilityLocation request: path=$path payload=$payload',
      );
      final response = await _dio.post(path, data: payload);
      logger.debug(
        'sendDriverAvailabilityLocation response: status=${response.statusCode} data=${response.data}',
      );
    } catch (error, stackTrace) {
      logger.warning(
        'sendDriverAvailabilityLocation failed',
        error,
        stackTrace,
      );
      // fire-and-forget : les erreurs réseau ne bloquent pas l'UX
    }
  }
}
