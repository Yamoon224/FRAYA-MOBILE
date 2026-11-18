/// Destinations les plus demandées, fournies par le serveur et gardées une semaine sur le téléphone.
///
/// Elles viennent des courses réellement terminées (un lieu n'est publié que s'il a été choisi par plusieurs
/// passagers distincts). Chercher un de ces lieux ne coûte alors aucun appel Google, ni à la frappe ni à la
/// sélection : leurs coordonnées sont déjà connues.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../data/sources/api_client.dart';
import '../../data/sources/local_storage.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

final _log = AppLogger.instance;

class PopularDestination {
  const PopularDestination({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  /// Partie de l'adresse après le nom (« Marcory, Abidjan »).
  String get locality {
    final index = address.indexOf(',');
    return index > 0 ? address.substring(index + 1).trim() : '';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };

  /// Null si l'entrée est inutilisable : une coordonnée douteuse fausserait le prix.
  static PopularDestination? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id']?.toString().trim() ?? '';
    final name = raw['name']?.toString().trim() ?? '';
    final address = raw['address']?.toString().trim() ?? '';
    final latRaw = raw['latitude'];
    final lngRaw = raw['longitude'];
    final lat = latRaw is num ? latRaw.toDouble() : null;
    final lng = lngRaw is num ? lngRaw.toDouble() : null;
    if (id.isEmpty || name.isEmpty || address.isEmpty) return null;
    if (lat == null || lng == null || !lat.isFinite || !lng.isFinite) {
      return null;
    }
    if (lat == 0 && lng == 0) return null;
    // Zone de service : la Côte d'Ivoire. Hors de ce cadre, on ignore l'entrée.
    if (lat < 4.0 || lat > 10.8 || lng < -8.7 || lng > -2.4) return null;
    return PopularDestination(
      id: id,
      name: name,
      address: address,
      latitude: lat,
      longitude: lng,
    );
  }
}

class PopularDestinationsStore {
  PopularDestinationsStore({
    LocalStorage? storage,
    DateTime Function()? now,
    Future<Object?> Function()? fetcher,
  }) : _storage = storage ?? LocalStorage.instance,
       _now = now ?? DateTime.now,
       _fetcher = fetcher;

  static final PopularDestinationsStore instance = PopularDestinationsStore();

  static const _storageKey = 'popular_destinations_v1';
  static const maxAge = Duration(days: 7);
  static const _retryAfterFailure = Duration(minutes: 30);
  static const _maxItems = 300;

  final LocalStorage _storage;
  final DateTime Function() _now;
  final Future<Object?> Function()? _fetcher;

  List<PopularDestination> _items = const [];
  bool _loaded = false;
  bool _refreshing = false;
  DateTime? _lastAttemptAt;

  @visibleForTesting
  void debugReset() {
    _items = const [];
    _loaded = false;
    _refreshing = false;
    _lastAttemptAt = null;
  }

  /// Lecture synchrone : la recherche locale ne peut pas attendre le réseau.
  List<PopularDestination> get items {
    _loadFromStorage();
    return _items;
  }

  void _loadFromStorage() {
    if (_loaded) return;
    _loaded = true;
    try {
      if (!_storage.isInitialized) {
        _loaded = false; // le stockage n'est pas encore prêt : on réessaiera
        return;
      }
      final raw = _storage.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw);
      if (data is Map) _items = _parse(data['items']);
    } catch (_) {
      _items = const [];
    }
  }

  List<PopularDestination> _parse(Object? raw) {
    if (raw is! List) return const [];
    final seen = <String>{};
    final out = <PopularDestination>[];
    for (final entry in raw) {
      final item = PopularDestination.fromJson(entry);
      if (item != null && seen.add(item.id)) out.add(item);
      if (out.length >= _maxItems) break;
    }
    return out;
  }

  int? _fetchedAtMs() {
    try {
      if (!_storage.isInitialized) return null;
      final raw = _storage.getString(_storageKey);
      if (raw == null || raw.isEmpty) return null;
      final data = jsonDecode(raw);
      final at = data is Map ? data['fetchedAt'] : null;
      return at is int ? at : null;
    } catch (_) {
      return null;
    }
  }

  bool get isStale {
    final at = _fetchedAtMs();
    if (at == null) return true;
    return _now().millisecondsSinceEpoch - at > maxAge.inMilliseconds;
  }

  /// Rafraîchit en arrière-plan si la liste a plus d'une semaine. Ne lève jamais d'erreur et ne se
  /// répète pas plus d'une fois toutes les 30 minutes après un échec.
  Future<void> refreshIfStale() async {
    if (_refreshing || !isStale) return;
    final last = _lastAttemptAt;
    if (last != null && _now().difference(last) < _retryAfterFailure) return;
    _refreshing = true;
    _lastAttemptAt = _now();
    try {
      if (_fetcher == null && !await _hasSession()) return;
      final body = await (_fetcher ?? _fetchFromApi)();
      final list = _extractList(body);
      if (list == null) return;
      final parsed = _parse(list);
      _items = parsed;
      _loaded = true;
      if (_storage.isInitialized) {
        await _storage.setString(
          _storageKey,
          jsonEncode({
            'fetchedAt': _now().millisecondsSinceEpoch,
            'items': parsed.map((e) => e.toJson()).toList(),
          }),
        );
      }
    } catch (e) {
      _log.warning('PopularDestinationsStore.refresh: $e');
    } finally {
      _refreshing = false;
    }
  }

  Object? _extractList(Object? body) {
    var current = body;
    // Réponse enveloppée : { data: [...] } (parfois { data: { data: [...] } }).
    for (var depth = 0; depth < 3 && current is Map; depth++) {
      current = current['data'];
    }
    return current is List ? current : null;
  }

  Future<Object?> _fetchFromApi() async {
    final response = await ApiClient.instance.dio.get(
      '/rides/maps/popular-destinations',
    );
    return response.data;
  }

  Future<bool> _hasSession() async {
    try {
      final key = AppConfig.instance.isDriver
          ? AppConstants.driverAccessTokenKey
          : AppConstants.accessTokenKey;
      return (await _storage.getSecure(key)) != null;
    } catch (_) {
      return false;
    }
  }
}
