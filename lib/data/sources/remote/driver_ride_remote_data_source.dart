library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../sources/api_client.dart';
import 'driver_position_queue.dart';

class DriverRideRemoteDataSource {
  DriverRideRemoteDataSource({
    Dio? dio,
    DriverPositionQueue? positionQueue,
    Stream<List<ConnectivityResult>>? connectivityChanges,
  }) : _dio = dio ?? ApiClient.instance.dio,
       _positionQueue = positionQueue ?? DriverPositionQueue(),
       _connectivityChanges = connectivityChanges;

  final Dio _dio;
  final DriverPositionQueue _positionQueue;
  final Stream<List<ConnectivityResult>>? _connectivityChanges;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isFlushing = false;

  // Plafond par rejeu : le reste part au prochain envoi ou au prochain changement de connectivité.
  static const int maxReplayPerRun = 50;

  static const int _historyPageSize = 100;
  // Garde-fou contre une méta incohérente (5000 courses au maximum).
  static const int _maxHistoryPages = 50;

  Future<List<Map<String, dynamic>>> getAllRides() async {
    try {
      // GET /rides/maps est paginé (20 par défaut) : sans parcourir les pages,
      // l'historique et les gains s'arrêtaient aux 20 dernières courses.
      final rides = <Map<String, dynamic>>[];
      var page = 1;
      var totalPages = 1;
      do {
        final response = await _dio.get(
          '/rides/maps',
          queryParameters: {'page': page, 'limit': _historyPageSize},
        );
        rides.addAll(_extractRides(response: response));
        totalPages = _extractTotalPages(response.data);
        page++;
      } while (page <= totalPages && page <= _maxHistoryPages);
      return rides;
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
        // Le backend lit radiusMeters (mètres) ; « radius » en km était ignoré.
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radiusMeters': (radiusKm * 1000).round(),
        },
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
    bool earlyStop = false,
  }) async {
    await _postDriverAction(
      '/rides/maps/$rideId/complete',
      data: {
        'rideId': int.tryParse(rideId) ?? rideId,
        'finalDistanceKm': finalDistanceKm.toString(),
        'finalDurationMin': finalDurationMin.toString(),
        'finalPrice': finalPrice.toString(),
        'additionnalFree': additionnalFreeSeconds,
        // Le serveur recalcule distance, durée et prix sur le trajet parcouru.
        if (earlyStop) 'earlyStop': true,
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

  int _extractTotalPages(dynamic data) {
    if (data is! Map) return 1;
    final meta = data['meta'];
    if (meta is! Map) return 1;
    return int.tryParse('${meta['totalPages']}') ?? 1;
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

  /// Envoie la position de course. Ne lève jamais d'erreur : en cas de coupure réseau la position
  /// est gardée en file puis rejouée dans l'ordre (prochain envoi réussi ou retour de connectivité).
  Future<void> sendDriverLocation({
    required String rideId,
    required int driverId,
    required double lat,
    required double lng,
  }) async {
    final position = QueuedDriverPosition(
      rideId: rideId,
      driverId: driverId,
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
    );

    if (_positionQueue.isNotEmpty) {
      // Des positions plus anciennes attendent : on s'ajoute derrière elles pour que le serveur
      // reçoive la plus récente en dernier, puis on rejoue sans bloquer l'appelant.
      _positionQueue.add(position);
      unawaited(flushPendingPositions());
      return;
    }

    try {
      await _postPosition(position);
    } catch (error, stackTrace) {
      logger.warning('sendDriverLocation failed', error, stackTrace);
      if (_isRetryableFailure(error)) {
        _enqueue(position);
      }
      // Refus 4xx (course terminée, chauffeur incorrect...) : inutile de réessayer.
    }
  }

  /// Rejoue les positions en attente, de la plus ancienne à la plus récente, par lot limité.
  /// S'arrête à la première coupure réseau ; une seule exécution à la fois (pas de doublon).
  Future<void> flushPendingPositions() async {
    if (_isFlushing) return;
    _isFlushing = true;
    try {
      var replayed = 0;
      while (replayed < maxReplayPerRun) {
        final next = _positionQueue.peek();
        if (next == null) break;
        try {
          await _postPosition(next);
        } catch (error, stackTrace) {
          if (_isRetryableFailure(error)) {
            logger.warning('flushPendingPositions paused', error, stackTrace);
            return;
          }
          // Refus métier : cette position ne sera jamais acceptée, on la jette.
        }
        _positionQueue.remove(next);
        replayed++;
      }
    } finally {
      _isFlushing = false;
      if (_positionQueue.isEmpty) {
        _stopConnectivityWatch();
      }
    }
  }

  void dispose() {
    _stopConnectivityWatch();
    _positionQueue.clear();
  }

  Future<void> _postPosition(QueuedDriverPosition position) async {
    final path = '/rides/maps/${position.rideId}/positions';
    final payload = position.toPayload();
    logger.debug('sendDriverLocation request: path=$path payload=$payload');
    final response = await _dio.post(path, data: payload);
    logger.debug(
      'sendDriverLocation response: status=${response.statusCode} data=${response.data}',
    );
  }

  /// Panne réseau ou serveur injoignable (pas de réponse, timeout, 5xx) ; un 4xx est un refus métier.
  static bool _isRetryableFailure(Object error) {
    if (error is! DioException) return false;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return status != null && status >= 500;
      case DioExceptionType.unknown:
        // Socket coupée sans réponse HTTP.
        return error.response == null;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
        return false;
    }
  }

  void _enqueue(QueuedDriverPosition position) {
    _positionQueue.add(position);
    _startConnectivityWatch();
  }

  // N'écoute la connectivité que tant que des positions attendent : pas d'abonnement inutile.
  void _startConnectivityWatch() {
    if (_connectivitySub != null) return;
    try {
      final stream =
          _connectivityChanges ?? Connectivity().onConnectivityChanged;
      _connectivitySub = stream.listen((results) {
        final hasTransport = results.any((r) => r != ConnectivityResult.none);
        if (hasTransport) unawaited(flushPendingPositions());
      }, onError: (_) {});
    } catch (error, stackTrace) {
      logger.warning('connectivity watch unavailable', error, stackTrace);
    }
  }

  void _stopConnectivityWatch() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
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
