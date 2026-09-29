import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/places_models.dart';
import '../utils/logger.dart';
import 'geocoding_service.dart';
import 'place_address_enrichment_service.dart';
import 'places_autocomplete_memory_cache.dart';
import 'places_cache_service.dart';
import 'places_service_support.dart';

final _log = AppLogger.instance;

class PlacesService {
  final Dio _googleDio;
  final PlacesCacheService _cacheService;
  final PlacesAutocompleteMemoryCache _autocompleteMemoryCache;
  final PlaceAddressEnrichmentService _addressEnrichmentService;

  static const minAutocompleteQueryLength = 3;
  static const forceAutocompleteRefreshQueryLength = 3;

  PlacesService({
    Dio? googleDio,
    PlacesCacheService? cacheService,
    PlacesAutocompleteMemoryCache? autocompleteMemoryCache,
    GeocodingService? geocodingService,
  }) : _googleDio = googleDio ?? Dio(),
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

    try {
      final response = await _googleDio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': normalizedQuery,
          'key': _apiKey,
          'language': language,
          'components': components,
          if (sessionToken != null && sessionToken.isNotEmpty)
            'sessiontoken': sessionToken,
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
          if (sessionToken != null && sessionToken.isNotEmpty)
            'sessiontoken': sessionToken,
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

  Future<List<PlaceDetails>> getNearbyPlaces({
    required double lat,
    required double lng,
    int radius = 10000, // 10km par défaut
    String type = 'point_of_interest',
    String language = 'fr',
  }) async {
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
          return results.map((json) => PlaceDetails.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      _log.error('Exception in getNearbyPlaces: $e');
      return [];
    }
  }
}
