import '../models/places_models.dart';
import '../utils/geo_distance_utils.dart';
import 'address_quality_service.dart';
import 'places_cache_service.dart';

class PlacesServiceSupport {
  const PlacesServiceSupport._();

  static const _qualityService = AddressQualityService();

  static List<PlaceSuggestion>? readPersistentAutocomplete(
    PlacesCacheService cacheService,
    String cacheKey, {
    double? originLat,
    double? originLng,
  }) {
    final placeIds = cacheService.readQueryPlaceIds(cacheKey);
    if (placeIds == null) return null;
    final suggestions = <PlaceSuggestion>[];
    for (final placeId in placeIds) {
      final details = cacheService.readDetails(placeId);
      if (details == null) return null;
      suggestions.add(
        suggestionFromDetails(
          details,
          originLat: originLat,
          originLng: originLng,
        ),
      );
    }
    return suggestions;
  }

  static PlaceSuggestion suggestionFromDetails(
    PlaceDetails details, {
    double? originLat,
    double? originLng,
  }) {
    final subtitle = _qualityService.subtitleFor(
      localityLabel: details.localityLabel,
      address: details.address,
      name: details.name,
    );
    final title = details.name.isNotEmpty
        ? details.name
        : primaryLabel(details.address);
    return PlaceSuggestion(
      placeId: details.placeId,
      description: subtitle.isNotEmpty ? subtitle : title,
      mainText: title,
      secondaryText: subtitle,
      localDetails: details,
      distanceMeters: GeoDistanceUtils.distanceMeters(
        originLat: originLat,
        originLng: originLng,
        destinationLat: details.latitude,
        destinationLng: details.longitude,
      ),
    );
  }

  static String normalizeQuery(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  static String autocompleteCacheKey({
    required String query,
    required String language,
    required String components,
    double? originLat,
    double? originLng,
  }) {
    final origin = originLat == null || originLng == null
        ? 'no_origin'
        : '${originLat.toStringAsFixed(2)},${originLng.toStringAsFixed(2)}';
    return Uri.encodeComponent('$query|$language|$components|$origin');
  }

  static String primaryLabel(String value) {
    final index = value.indexOf(',');
    return index > 0 ? value.substring(0, index).trim() : value;
  }
}
