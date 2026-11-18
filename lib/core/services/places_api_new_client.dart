/// Client de Places API (New) : autocomplétion et détails d'un lieu.
///
/// Intérêt : la nouvelle API facture les détails selon les CHAMPS demandés. Adresse, composants d'adresse et
/// coordonnées relèvent du palier « Essentials », nettement moins cher que le palier « Pro » (nom du lieu).
/// Le nom est déjà connu par l'autocomplétion : on ne le redemande pas.
///
/// Les réponses sont converties au format de l'ancienne API, que tout le reste de l'application comprend déjà
/// ([PlaceSuggestion.fromJson], [PlaceDetails.fromJson]) : rien d'autre ne change.
///
/// Sécurité de déploiement : si l'API n'est pas activée pour la clé (403) ou si la requête est refusée, ce
/// client rend `null` et l'appelant retombe sur l'ancienne API. Un 403 coupe la nouvelle API pendant une heure
/// pour ne pas payer de latence à chaque frappe.
library;

import 'package:dio/dio.dart';

import '../utils/logger.dart';

final _log = AppLogger.instance;

class PlacesApiNewClient {
  PlacesApiNewClient(this._dio, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Dio _dio;
  final DateTime Function() _now;

  static const _base = 'https://places.googleapis.com/v1';
  static const _disableDuration = Duration(hours: 1);

  /// Partagé par toute l'application : une clé non autorisée l'est pour tous les appels.
  static DateTime? _disabledUntil;

  /// Pour les tests.
  static void debugReset() => _disabledUntil = null;

  bool get isAvailable {
    final until = _disabledUntil;
    return until == null || _now().isAfter(until);
  }

  static const _autocompleteMask =
      'suggestions.placePrediction.placeId,'
      'suggestions.placePrediction.text.text,'
      'suggestions.placePrediction.structuredFormat,'
      'suggestions.placePrediction.types,'
      'suggestions.placePrediction.distanceMeters';

  /// Champs « Essentials » : adresse, composants, coordonnées, types.
  static const essentialsDetailsMask =
      'id,formattedAddress,adrFormatAddress,shortFormattedAddress,'
      'addressComponents,location,types';

  /// Prédictions au format de l'ancienne API, ou `null` si l'appelant doit utiliser l'ancienne API.
  Future<List<Map<String, dynamic>>?> autocomplete({
    required String apiKey,
    required String input,
    required String language,
    required String components,
    required double biasLat,
    required double biasLng,
    required int biasRadiusMeters,
    String? sessionToken,
    double? originLat,
    double? originLng,
    CancelToken? cancelToken,
  }) async {
    final regionCodes = _regionCodes(components);
    final body = <String, dynamic>{
      'input': input,
      'languageCode': language,
      if (regionCodes.isNotEmpty) 'includedRegionCodes': regionCodes,
      'locationBias': {
        'circle': {
          'center': {'latitude': biasLat, 'longitude': biasLng},
          // Plafond de l'API : 50 000 m.
          'radius': biasRadiusMeters.clamp(1, 50000).toDouble(),
        },
      },
      if (originLat != null && originLng != null)
        'origin': {'latitude': originLat, 'longitude': originLng},
      if (sessionToken != null && sessionToken.isNotEmpty)
        'sessionToken': sessionToken,
    };

    final data = await _send(
      () => _dio.post(
        '$_base/places:autocomplete',
        data: body,
        cancelToken: cancelToken,
        options: Options(headers: _headers(apiKey, _autocompleteMask)),
      ),
      'autocomplete',
    );
    if (data == null) return null;

    final suggestions = data['suggestions'];
    if (suggestions is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in suggestions) {
      final prediction = item is Map ? item['placePrediction'] : null;
      if (prediction is! Map) continue; // requêtes de lieu : non utilisées
      final placeId = prediction['placeId']?.toString() ?? '';
      if (placeId.isEmpty) continue;
      final text = _text(prediction['text']);
      final structured = prediction['structuredFormat'];
      out.add({
        'place_id': placeId,
        'description': text,
        'structured_formatting': {
          'main_text': structured is Map ? _text(structured['mainText']) : text,
          'secondary_text': structured is Map
              ? _text(structured['secondaryText'])
              : '',
        },
        'types': (prediction['types'] as List?)?.cast<String>() ?? const [],
        if (prediction['distanceMeters'] is num)
          'distance_meters': prediction['distanceMeters'],
      });
    }
    return out;
  }

  /// Détails au format de l'ancienne API (`result`), ou `null` pour retomber sur l'ancienne API.
  /// [knownName] : nom déjà fourni par l'autocomplétion ; sans lui, le nom est demandé (palier Pro).
  Future<Map<String, dynamic>?> placeDetails({
    required String apiKey,
    required String placeId,
    required String language,
    String? sessionToken,
    String? knownName,
  }) async {
    final needName = knownName == null || knownName.trim().isEmpty;
    final data = await _send(
      () => _dio.get(
        '$_base/places/$placeId',
        queryParameters: {
          'languageCode': language,
          if (sessionToken != null && sessionToken.isNotEmpty)
            'sessionToken': sessionToken,
        },
        options: Options(
          headers: _headers(
            apiKey,
            needName
                ? '$essentialsDetailsMask,displayName'
                : essentialsDetailsMask,
          ),
        ),
      ),
      'details',
    );
    if (data == null) return null;

    final location = data['location'];
    final lat = location is Map ? location['latitude'] : null;
    final lng = location is Map ? location['longitude'] : null;
    if (lat is! num || lng is! num) return null;

    return {
      'place_id': data['id']?.toString() ?? placeId,
      'name': needName ? _text(data['displayName']) : knownName.trim(),
      'formatted_address': data['formattedAddress'],
      'adr_address': data['adrFormatAddress'],
      'vicinity': data['shortFormattedAddress'],
      'types': (data['types'] as List?)?.cast<String>() ?? const [],
      'geometry': {
        'location': {'lat': lat, 'lng': lng},
      },
      'address_components': [
        for (final c in (data['addressComponents'] as List? ?? const []))
          if (c is Map)
            {
              'long_name': c['longText']?.toString() ?? '',
              'short_name': c['shortText']?.toString() ?? '',
              'types': (c['types'] as List?)?.cast<String>() ?? const [],
            },
      ],
    };
  }

  Future<Map<String, dynamic>?> _send(
    Future<Response<dynamic>> Function() call,
    String what,
  ) async {
    try {
      final response = await call();
      final data = response.data;
      if (response.statusCode == 200 && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } on DioException catch (e) {
      // Recherche abandonnée par l'utilisateur : ce n'est pas un échec de l'API.
      if (CancelToken.isCancel(e)) rethrow;
      final status = e.response?.statusCode;
      if (status == 403) {
        // API non activée ou non autorisée pour cette clé : on la laisse de côté une heure.
        _disabledUntil = _now().add(_disableDuration);
        _log.warning(
          'Places API (New) indisponible (403) : retour à l\'ancienne API pendant 1 h.',
        );
        return null;
      }
      if (status == 400 || status == 404) {
        _log.warning(
          'Places API (New) $what refusée ($status) : ancienne API utilisée.',
        );
        return null;
      }
      rethrow; // réseau, 5xx : même traitement que l'ancienne API
    }
  }

  Map<String, String> _headers(String apiKey, String fieldMask) => {
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': apiKey,
    'X-Goog-FieldMask': fieldMask,
  };

  /// `country:ci` (ancienne API) → `['ci']`.
  List<String> _regionCodes(String components) {
    return components
        .split('|')
        .where((part) => part.startsWith('country:'))
        .map((part) => part.substring('country:'.length).toLowerCase())
        .where((code) => code.length == 2)
        .toList();
  }

  String _text(Object? node) {
    if (node is Map) return node['text']?.toString() ?? '';
    return node?.toString() ?? '';
  }
}
