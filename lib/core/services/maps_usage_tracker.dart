/// Suivi de la consommation Google Maps faite directement par l'application.
///
/// Le serveur ne voit pas ces appels (REST appelés depuis le téléphone, SDK carte et navigation) :
/// l'application les déclare donc au backend par lots, pour le tableau de bord admin.
/// Aucune adresse ni coordonnée n'est envoyée, seulement la nature, la durée et le statut de l'appel.
/// Le suivi ne doit jamais gêner l'usage : toute erreur est absorbée.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/sources/api_client.dart';
import '../../data/sources/local_storage.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

final _log = AppLogger.instance;

/// Noms alignés sur l'énumération `MapsApiService` du backend.
enum MapsService {
  placesAutocomplete('PLACES_AUTOCOMPLETE'),
  placeDetails('PLACE_DETAILS'),
  nearbySearch('NEARBY_SEARCH'),
  directions('DIRECTIONS'),
  geocoding('GEOCODING'),
  distanceMatrix('DISTANCE_MATRIX'),
  routes('ROUTES'),
  mapLoad('MAP_LOAD'),
  navigation('NAVIGATION');

  const MapsService(this.wireName);
  final String wireName;
}

class _MapsEvent {
  _MapsEvent({
    required this.service,
    required this.success,
    required this.durationMs,
    this.googleStatus,
    this.errorMessage,
  }) : occurredAt = DateTime.now().toUtc();

  final MapsService service;
  final bool success;
  final int durationMs;
  final String? googleStatus;
  final String? errorMessage;
  final DateTime occurredAt;

  Map<String, dynamic> toJson() => {
    'service': service.wireName,
    'success': success,
    'durationMs': durationMs,
    if (googleStatus != null) 'googleStatus': googleStatus,
    if (errorMessage != null) 'errorMessage': errorMessage,
    'occurredAt': occurredAt.toIso8601String(),
  };
}

class MapsUsageTracker {
  MapsUsageTracker._();
  static final MapsUsageTracker instance = MapsUsageTracker._();

  static const _batchSize = 20;
  static const _maxBuffered = 500;
  static const _flushInterval = Duration(seconds: 20);

  final List<_MapsEvent> _buffer = [];
  Timer? _timer;
  bool _flushing = false;
  String? _appVersion;

  /// Pour les tests : remplace l'envoi réseau.
  Future<Response<dynamic>> Function(Map<String, dynamic> body)? sender;

  // Une erreur réseau peut citer l'URL complète : on masque la clé API avant tout envoi.
  static String _redact(String message) => message
      .replaceAll(RegExp(r'key=[^&s]+', caseSensitive: false), 'key=***')
      .replaceAll(RegExp(r'AIza[0-9A-Za-z_-]{20,}'), '***');

  void record(
    MapsService service, {
    required bool success,
    int durationMs = 0,
    String? googleStatus,
    String? errorMessage,
  }) {
    try {
      if (_buffer.length >= _maxBuffered) _buffer.removeAt(0);
      _buffer.add(
        _MapsEvent(
          service: service,
          success: success,
          durationMs: durationMs,
          googleStatus: googleStatus,
          errorMessage: errorMessage == null
              ? null
              : _redact(
                  errorMessage.length <= 500
                      ? errorMessage
                      : errorMessage.substring(0, 500),
                ),
        ),
      );
      _timer ??= Timer.periodic(_flushInterval, (_) => flush());
      if (_buffer.length >= _batchSize) unawaited(flush());
    } catch (e) {
      _log.warning('MapsUsageTracker.record: $e');
    }
  }

  /// Chargement d'une carte (SDK natif : gratuit, mais utile pour mesurer l'usage).
  void recordMapLoad() => record(MapsService.mapLoad, success: true);

  Future<void> flush() async {
    if (_flushing || _buffer.isEmpty) return;
    _flushing = true;
    final batch = _buffer.take(50).toList();
    try {
      if (sender == null && !await _hasSession()) return;
      _appVersion ??= await _readVersion();
      final body = {
        'platform': Platform.isIOS ? 'ios' : 'android',
        if (_appVersion != null) 'appVersion': _appVersion,
        'events': batch.map((e) => e.toJson()).toList(),
      };
      if (sender != null) {
        await sender!(body);
      } else {
        await ApiClient.instance.dio.post(
          '/maps-usage/mobile-events',
          data: body,
        );
      }
      _buffer.removeRange(0, batch.length);
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      // Lot refusé (validation) : on l'abandonne pour ne pas le renvoyer en boucle.
      if (status >= 400 && status < 500 && status != 401 && status != 429) {
        _buffer.removeRange(0, batch.length);
      }
    } catch (e) {
      _log.warning('MapsUsageTracker.flush: $e');
    } finally {
      _flushing = false;
    }
  }

  Future<bool> _hasSession() async {
    try {
      final key = AppConfig.instance.isDriver
          ? AppConstants.driverAccessTokenKey
          : AppConstants.accessTokenKey;
      return (await LocalStorage.instance.getSecure(key)) != null;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _readVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return null;
    }
  }
}

/// Intercepteur Dio à poser sur tout client qui appelle `*.googleapis.com`.
class MapsUsageInterceptor extends Interceptor {
  static const _startKey = 'maps_usage_started_at';

  static MapsService? classify(Uri uri) {
    final host = uri.host;
    final path = uri.path;
    if (host == 'routes.googleapis.com') return MapsService.routes;
    if (host != 'maps.googleapis.com') return null;
    if (path.contains('/place/autocomplete')) {
      return MapsService.placesAutocomplete;
    }
    if (path.contains('/place/details')) return MapsService.placeDetails;
    if (path.contains('/place/nearbysearch')) return MapsService.nearbySearch;
    if (path.contains('/directions/')) return MapsService.directions;
    if (path.contains('/geocode/')) return MapsService.geocoding;
    if (path.contains('/distancematrix/')) return MapsService.distanceMatrix;
    return null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _track(response.requestOptions, () {
      final data = response.data;
      // L'API REST répond 200 avec un champ `status` ; l'API Routes n'en a pas.
      final status = data is Map ? data['status']?.toString() : null;
      final ok =
          response.statusCode == 200 &&
          (status == null || status == 'OK' || status == 'ZERO_RESULTS');
      return (
        ok,
        status ?? response.statusCode?.toString(),
        data is Map ? data['error_message']?.toString() : null,
      );
    });
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _track(
      err.requestOptions,
      () => (
        false,
        err.response?.statusCode?.toString() ?? err.type.name,
        err.message,
      ),
    );
    handler.next(err);
  }

  void _track(
    RequestOptions options,
    (bool, String?, String?) Function() outcome,
  ) {
    try {
      final service = classify(options.uri);
      if (service == null) return;
      final started = options.extra[_startKey] as int?;
      final (ok, status, message) = outcome();
      MapsUsageTracker.instance.record(
        service,
        success: ok,
        durationMs: started == null
            ? 0
            : DateTime.now().millisecondsSinceEpoch - started,
        googleStatus: status,
        errorMessage: ok ? null : message,
      );
    } catch (_) {
      // Le suivi ne doit jamais perturber l'appel Google.
    }
  }
}

/// Crée un client Dio prêt pour les appels Google, avec suivi de consommation.
Dio createGoogleDio() => Dio()..interceptors.add(MapsUsageInterceptor());
