import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'address_formatter_service.dart';
import 'maps_usage_tracker.dart';
import '../../data/sources/local_storage.dart';
import '../utils/logger.dart';

final _log = AppLogger.instance;

class GeocodingService {
  final Dio _dio;
  final AddressFormatterService _addressFormatter;

  GeocodingService({
    Dio? dio,
    AddressFormatterService? addressFormatter,
    LocalStorage? storage,
    DateTime Function()? now,
  }) : _dio = dio ?? createGoogleDio(),
       _addressFormatter = addressFormatter ?? const AddressFormatterService(),
       _storage = storage ?? LocalStorage.instance,
       _now = now ?? DateTime.now;

  final LocalStorage _storage;
  final DateTime Function() _now;

  /// Un même endroit (arrondi à ~11 m) n'est géocodé qu'une fois par semaine :
  /// chaque appel Geocoding est facturé, et une adresse de rue ne change pas.
  static const _cacheTtl = Duration(days: 7);
  static const _cachePrefix = 'geocode_cache_';
  static const _memoryLimit = 200;
  final Map<String, (AddressParts, String, int)> _memory = {};

  String _cacheKey(double lat, double lng) =>
      '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

  (AddressParts, String)? _readCache(String key) {
    final nowMs = _now().millisecondsSinceEpoch;
    final hot = _memory[key];
    if (hot != null) {
      if (nowMs - hot.$3 <= _cacheTtl.inMilliseconds) return (hot.$1, hot.$2);
      _memory.remove(key);
    }
    try {
      if (!_storage.isInitialized) return null;
      final raw = _storage.getString('$_cachePrefix$key');
      if (raw == null || raw.isEmpty) return null;
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      final cachedAt = data['cachedAt'];
      if (cachedAt is! int || nowMs - cachedAt > _cacheTtl.inMilliseconds) {
        _storage.remove('$_cachePrefix$key');
        return null;
      }
      final parts = AddressParts(
        streetOrQuarter: (data['street'] ?? '').toString(),
        commune: (data['commune'] ?? '').toString(),
      );
      final placeId = (data['placeId'] ?? '').toString();
      _remember(key, parts, placeId, cachedAt);
      return (parts, placeId);
    } catch (_) {
      return null;
    }
  }

  void _remember(String key, AddressParts parts, String placeId, int at) {
    if (_memory.length >= _memoryLimit) _memory.remove(_memory.keys.first);
    _memory[key] = (parts, placeId, at);
  }

  Future<void> _writeCache(
    String key,
    AddressParts parts,
    String placeId,
  ) async {
    final at = _now().millisecondsSinceEpoch;
    _remember(key, parts, placeId, at);
    try {
      if (!_storage.isInitialized) return;
      await _storage.setString(
        '$_cachePrefix$key',
        jsonEncode({
          'cachedAt': at,
          'street': parts.streetOrQuarter,
          'commune': parts.commune,
          'placeId': placeId,
        }),
      );
    } catch (_) {
      // Le cache disque est un confort : on garde la version en mémoire.
    }
  }

  String get _apiKey {
    try {
      return dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Récupère la commune, le quartier et le placeId Google à partir de coordonnées GPS.
  ///
  /// Retourne un objet contenant 'commune', 'quartier', 'formatted' et 'placeId'.
  Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
    final (parts, placeId) = await resolveAddressWithPlaceId(lat, lng);
    return {
      'commune': parts?.commune ?? '',
      'quartier': parts?.streetOrQuarter ?? '',
      'formatted': parts == null ? '' : _addressFormatter.format(parts),
      'placeId': placeId,
    };
  }

  Future<AddressParts?> resolveAddress(double lat, double lng) async {
    return (await resolveAddressWithPlaceId(lat, lng)).$1;
  }

  Future<(AddressParts?, String)> resolveAddressWithPlaceId(
    double lat,
    double lng,
  ) async {
    final key = _cacheKey(lat, lng);
    final cached = _readCache(key);
    if (cached != null) return (cached.$1, cached.$2);

    final result = await _fetchAddressWithPlaceId(lat, lng);
    // Seuls les succès sont conservés : un échec réseau doit pouvoir être retenté.
    final parts = result.$1;
    if (parts != null) await _writeCache(key, parts, result.$2);
    return result;
  }

  Future<(AddressParts?, String)> _fetchAddressWithPlaceId(
    double lat,
    double lng,
  ) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': _apiKey,
          'language': 'fr',
          'region': 'ci',
        },
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            final bestResult = _bestResult(results);
            if (bestResult != null) {
              final parts = _partsFromResult(bestResult);
              final placeId = (bestResult['place_id'] as String?) ?? '';
              return (parts, placeId);
            }
          }
        } else {
          _log.error('Google Geocoding error: ${data['status']}');
        }
      }
      return (null, '');
    } catch (e) {
      _log.error('Exception in reverseGeocode: $e');
      return (null, '');
    }
  }

  Map<String, dynamic>? _bestResult(List results) {
    Map<String, dynamic>? best;
    var bestScore = -1000;
    for (final result in results) {
      if (result is! Map) continue;
      final candidate = Map<String, dynamic>.from(result);
      final score = _scoreResult(candidate);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }
    return best;
  }

  AddressParts _partsFromResult(Map<String, dynamic> result) {
    final components = (result['address_components'] as List?) ?? const [];
    final values = _GeocodingComponents();
    for (final component in components) {
      if (component is! Map) continue;
      values.add(
        (component['long_name'] ?? '').toString(),
        (component['types'] as List?) ?? const [],
      );
    }
    final commune = values.knownCommuneCandidates.firstWhere(
      (value) =>
          _addressFormatter.isKnownCommune(value) &&
          !_addressFormatter.isAbidjanToken(value),
      orElse: () => values.communeCandidates.firstWhere(
        (value) => value.isNotEmpty,
        orElse: () => '',
      ),
    );
    return _addressFormatter.fromComponents(
      street: values.street,
      quarter: values.quarter,
      commune: commune,
      raw: (result['formatted_address'] ?? '').toString(),
    );
  }

  int _scoreResult(Map<String, dynamic> result) {
    final components = (result['address_components'] as List?) ?? [];
    var score = 0;
    final resultTypes = (result['types'] as List?) ?? const [];
    if (resultTypes.contains('plus_code')) score -= 20;
    if (resultTypes.contains('street_address')) score += 5;
    if (resultTypes.contains('route')) score += 3;
    for (final component in components) {
      if (component is! Map) continue;
      final types = (component['types'] as List?) ?? [];
      final name = (component['long_name'] ?? '').toString();
      if (types.contains('street_number')) score += 3;
      if (types.contains('route')) score += 5;
      if (types.contains('neighborhood')) score += 4;
      if (types.contains('sublocality_level_2')) score += 3;
      if (types.contains('sublocality_level_3')) score += 3;
      if (_addressFormatter.isKnownCommune(name) &&
          !_addressFormatter.isAbidjanToken(name)) {
        score += 4;
      }
    }
    return score;
  }
}

class _GeocodingComponents {
  String streetNumber = '';
  String route = '';
  String neighborhood = '';
  String sublocalityLevel1 = '';
  String sublocalityLevel2 = '';
  String sublocalityLevel3 = '';
  String adminLevel2 = '';
  String adminLevel3 = '';
  String locality = '';

  String get street =>
      [streetNumber, route].where((part) => part.isNotEmpty).join(' ');

  String get quarter => [
    neighborhood,
    sublocalityLevel3,
    sublocalityLevel2,
  ].firstWhere((value) => value.isNotEmpty, orElse: () => '');

  List<String> get communeCandidates => [
    sublocalityLevel1,
    adminLevel3,
    adminLevel2,
    locality,
  ];

  List<String> get knownCommuneCandidates => [
    neighborhood,
    sublocalityLevel3,
    sublocalityLevel2,
    ...communeCandidates,
  ];

  void add(String name, List types) {
    if (types.contains('street_number')) streetNumber = name;
    if (types.contains('route')) route = name;
    if (types.contains('neighborhood')) neighborhood = name;
    if (types.contains('sublocality_level_1')) sublocalityLevel1 = name;
    if (types.contains('sublocality_level_2')) sublocalityLevel2 = name;
    if (types.contains('sublocality_level_3')) sublocalityLevel3 = name;
    if (types.contains('administrative_area_level_2')) adminLevel2 = name;
    if (types.contains('administrative_area_level_3')) adminLevel3 = name;
    if (types.contains('locality')) locality = name;
  }
}
