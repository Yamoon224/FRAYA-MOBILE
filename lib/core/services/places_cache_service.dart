import 'dart:convert';

import '../../data/sources/local_storage.dart';
import '../models/places_models.dart';
import 'address_quality_service.dart';

class PlacesCacheService {
  PlacesCacheService({
    LocalStorage? storage,
    DateTime Function()? now,
    this.ttl = const Duration(days: 30),
    this.partialTtl = const Duration(hours: 24),
    this.qualityService = const AddressQualityService(),
  }) : _storage = storage ?? LocalStorage.instance,
       _now = now ?? DateTime.now;

  static const _detailsPrefix = 'places_cache_details_';
  static const _queryPrefix = 'places_cache_query_';

  final LocalStorage _storage;
  final DateTime Function() _now;
  final Duration ttl;
  final Duration partialTtl;
  final AddressQualityService qualityService;

  static const schemaVersion = 2;

  PlaceDetails? readDetails(String placeId) {
    if (!_storage.isInitialized || placeId.isEmpty) return null;
    final raw = _storage.getString('$_detailsPrefix$placeId');
    if (raw == null || raw.isEmpty) return null;
    final data = _decode(raw);
    if (data == null) return null;
    final detailsJson = data['details'];
    if (detailsJson is! Map<String, dynamic>) return null;
    final details = PlaceDetails.fromLocalJson(detailsJson);
    final quality = qualityService.assess(
      details.localityLabel ?? details.address,
    );
    final isLegacyPoor =
        data['schemaVersion'] != schemaVersion &&
        quality != AddressQuality.complete;
    final maxAge = quality == AddressQuality.complete ? ttl : partialTtl;
    if (isLegacyPoor || _isExpired(data, maxAge)) {
      _storage.remove('$_detailsPrefix$placeId');
      return null;
    }
    return details;
  }

  Future<void> saveDetails(PlaceDetails details) async {
    if (!_storage.isInitialized || details.placeId.isEmpty) return;
    await _storage.setString(
      '$_detailsPrefix${details.placeId}',
      jsonEncode({
        'schemaVersion': schemaVersion,
        'cachedAt': _now().millisecondsSinceEpoch,
        'quality': qualityService
            .assess(details.localityLabel ?? details.address)
            .name,
        'details': details.toLocalJson(),
      }),
    );
  }

  List<String>? readQueryPlaceIds(String cacheKey) {
    if (!_storage.isInitialized || cacheKey.isEmpty) return null;
    final raw = _storage.getString('$_queryPrefix$cacheKey');
    if (raw == null || raw.isEmpty) return null;
    final data = _decode(raw);
    if (data == null || _isExpired(data, ttl)) {
      _storage.remove('$_queryPrefix$cacheKey');
      return null;
    }
    final ids = data['placeIds'];
    if (ids is! List) return null;
    return ids.map((id) => id.toString()).where((id) => id.isNotEmpty).toList();
  }

  Future<void> saveQueryPlaceIds(String cacheKey, List<String> placeIds) async {
    if (!_storage.isInitialized || cacheKey.isEmpty) return;
    await _storage.setString(
      '$_queryPrefix$cacheKey',
      jsonEncode({
        'cachedAt': _now().millisecondsSinceEpoch,
        'placeIds': placeIds,
      }),
    );
  }

  bool _isExpired(Map<String, dynamic> data, Duration maxAge) {
    final cachedAt = data['cachedAt'];
    if (cachedAt is! int) return true;
    return _now().millisecondsSinceEpoch - cachedAt > maxAge.inMilliseconds;
  }

  Map<String, dynamic>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
