import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/places_models.dart';
import '../utils/logger.dart';
import 'geocoding_service.dart';
import 'place_address_enrichment_service.dart';
import 'places_autocomplete_memory_cache.dart';
import 'places_cache_service.dart';
import 'places_service_support.dart';
import 'places_session.dart';

final _log = AppLogger.instance;

class PlacesService {
  final Dio _googleDio;
  final PlacesCacheService _cacheService;
  final PlacesAutocompleteMemoryCache _autocompleteMemoryCache;
  final PlaceAddressEnrichmentService _addressEnrichmentService;
  final PlacesSession _session;

  /// Lieux proches déjà demandés : la recherche Nearby est l'appel le plus cher
  /// et sa réponse ne change pas d'une ouverture de l'écran à l'autre.
  static final Map<String, _NearbyEntry> _nearbyCache = {};
  static const _nearbyTtl = Duration(hours: 12);

  /// Centre d'Abidjan : biais de recherche quand la position est inconnue.
  static const abidjanLat = 5.3245;
  static const abidjanLng = -4.0201;
  static const biasRadiusMeters = 50000;

  static const minAutocompleteQueryLength = 3;
  static const forceAutocompleteRefreshQueryLength = 3;

  PlacesService({
    Dio? googleDio,
    PlacesCacheService? cacheService,
    PlacesAutocompleteMemoryCache? autocompleteMemoryCache,
    GeocodingService? geocodingService,
    PlacesSession? session,
  }) : _session = session ?? PlacesSession.shared,
       _googleDio = googleDio ?? Dio(),
       _cacheService = cacheService ?? PlacesCacheService(),
       _autocompleteMemoryCache =
           autocompleteMemoryCache ?? PlacesAutocompleteMemoryCache(),
       _addressEnrichmentService = PlaceAddressEnrichmentService(
         geocodingService: geocodingService,
       );

  String get _apiKey {
    try {
      return dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
    String query, {
    String? sessionToken,
    String language = 'fr',
    String components = 'country:ci',
    double? originLat,
    double? originLng,
    bool bypassCache = false,
    CancelToken? cancelToken,
    bool useSession = true,
  }) async {
    final normalizedQuery = PlacesServiceSupport.normalizeQuery(query);
    if (normalizedQuery.length < minAutocompleteQueryLength) return [];

    final cacheKey = PlacesServiceSupport.autocompleteCacheKey(
      query: normalizedQuery,
      language: language,
      components: components,
      originLat: originLat,
      originLng: originLng,
    );
    if (!bypassCache) {
      final memoryHit = _autocompleteMemoryCache.read(cacheKey);
      if (memoryHit != null) return memoryHit;

      final persistentHit = PlacesServiceSupport.readPersistentAutocomplete(
        _cacheService,
        cacheKey,
        originLat: originLat,
        originLng: originLng,
      );
      if (persistentHit != null) {
        _autocompleteMemoryCache.save(cacheKey, persistentHit);
        return persistentHit;
      }
    }

    // Toutes les frappes d'une recherche partagent un même token ; il est clos
    // par l'appel Place Details de la sélection.
    // `useSession: false` pour un appel isolé (sans Place Details derrière) :
    // facturé à la requête, sans ouvrir de session qui ne serait jamais close.
    final token = !useSession
        ? null
        : (sessionToken != null && sessionToken.isNotEmpty)
        ? sessionToken
        : _session.current();

    try {
      final response = await _googleDio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        cancelToken: cancelToken,
        queryParameters: {
          'input': normalizedQuery,
          'key': _apiKey,
          'language': language,
          // Restreint à la Côte d'Ivoire.
          'components': components,
          // Biais vers la position de l'utilisateur, sinon vers Abidjan.
          'locationbias':
              'circle:$biasRadiusMeters@'
              '${originLat ?? abidjanLat},${originLng ?? abidjanLng}',
          if (token != null) 'sessiontoken': token,
          // Fournir `origin` fait renvoyer `distance_meters` par prédiction.
          if (originLat != null && originLng != null)
            'origin': '$originLat,$originLng',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final predictions = data['predictions'] as List;
          final suggestions = predictions
              .map((json) => PlaceSuggestion.fromJson(json))
              .toList();
          _autocompleteMemoryCache.save(cacheKey, suggestions);
          await _cacheService.saveQueryPlaceIds(
            cacheKey,
            suggestions.map((s) => s.placeId).toList(),
          );
          return suggestions;
        } else {
          _log.error('Google Places Autocomplete error: ${data['status']}');
        }
      }
      return [];
    } on DioException catch (e) {
      // Requête annulée car l'utilisateur a continué à taper : pas une erreur.
      if (CancelToken.isCancel(e)) return [];
      _log.error('Exception in getAutocompleteSuggestions: $e');
      return [];
    } catch (e) {
      _log.error('Exception in getAutocompleteSuggestions: $e');
      return [];
    }
  }

  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String language = 'fr',
  }) async {
    // Cet appel clôture la session d'autocomplete : on consomme le token (il ne
    // doit plus être réutilisé), même si le lieu vient du cache.
    final closingToken = (sessionToken != null && sessionToken.isNotEmpty)
        ? sessionToken
        : _session.close();

    final cached = _cacheService.readDetails(placeId);
    if (cached != null) return cached;

    try {
      final response = await _googleDio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'language': language,
          'fields':
              'place_id,name,formatted_address,adr_address,'
              'address_components,geometry,vicinity,types',
          if (closingToken != null) 'sessiontoken': closingToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final parsed = PlaceDetails.fromJson(data['result']);
          final details = await _addressEnrichmentService.enrichIfNeeded(
            parsed,
          );
          await _cacheService.saveDetails(details);
          return details;
        } else {
          _log.error('Google Places Details error: ${data['status']}');
        }
      }
      return null;
    } catch (e) {
      _log.error('Exception in getPlaceDetails: $e');
      return null;
    }
  }

  /// Termine la session d'autocomplete en cours sans appeler Place Details
  /// (recherche sans résultat ou abandonnée) : la prochaine recherche repart
  /// avec un nouveau token au lieu de traîner une session périmée.
  void endSearchSession() => _session.close();

  /// Détails déjà en cache local, sans aucun appel réseau (ni facturation).
  PlaceDetails? getCachedPlaceDetails(String placeId) =>
      _cacheService.readDetails(placeId);

  Future<List<PlaceDetails>> getNearbyPlaces({
    required double lat,
    required double lng,
    int radius = 10000, // 10km par défaut
    String type = 'point_of_interest',
    String language = 'fr',
  }) async {
    // Clé arrondie (~1 km) : deux ouvertures de l'écran au même endroit ne
    // refacturent pas la recherche.
    final cacheKey =
        '${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}|$radius|$type|$language';
    final cached = _nearbyCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.at) < _nearbyTtl) {
      return cached.places;
    }

    try {
      final response = await _googleDio.get(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
        queryParameters: {
          'location': '$lat,$lng',
          'radius': radius,
          'type': type,
          'key': _apiKey,
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          // On transforme les résultats en PlaceDetails
          final places = results
              .map((json) => PlaceDetails.fromJson(json))
              .toList();
          if (places.isNotEmpty) {
            _nearbyCache[cacheKey] = _NearbyEntry(places, DateTime.now());
          }
          return places;
        }
      }
      return [];
    } catch (e) {
      _log.error('Exception in getNearbyPlaces: $e');
      return [];
    }
  }
}

class _NearbyEntry {
  const _NearbyEntry(this.places, this.at);

  final List<PlaceDetails> places;
  final DateTime at;
}
