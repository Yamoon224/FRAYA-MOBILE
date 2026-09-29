import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/favorite_place.dart';
import '../../core/models/places_models.dart';
import '../../core/services/favorite_places_service.dart';
import '../../core/services/address_quality_service.dart';
import '../../core/services/recent_places_service.dart';
import '../../core/services/saved_places_service.dart';
import '../../core/utils/geo_distance_utils.dart';
import '../../features/passenger/auth/providers/passenger_auth_provider.dart';
import '../../features/passenger/auth/providers/passenger_auth_user_id.dart';

Future<List<PlaceSuggestion>> localPlaceSuggestions(
  Ref ref,
  String query, {
  double? originLat,
  double? originLng,
}) async {
  final userId = _passengerUserId(ref);
  final recent = await RecentPlacesService(userId).getAll();
  final saved = await SavedPlacesService(userId).getCachedAddresses();
  final favorites = await FavoritePlacesService(userId: userId).getAll();

  final suggestions = <PlaceSuggestion>[
    ...recent.map(
      (place) => _suggestionFromPlaceDetails(
        place,
        originLat: originLat,
        originLng: originLng,
      ),
    ),
    ...saved.map(
      (address) => _suggestionFromPlaceDetails(
        address.place,
        title: address.label,
        originLat: originLat,
        originLng: originLng,
      ),
    ),
    ...favorites.map(
      (favorite) => _suggestionFromFavoritePlace(
        favorite,
        originLat: originLat,
        originLng: originLng,
      ),
    ),
  ];

  final seen = <String>{};
  return suggestions
      .where((suggestion) {
        if (!_matchesQuery(suggestion, query)) return false;
        final key = suggestion.placeId.isNotEmpty
            ? suggestion.placeId
            : '${suggestion.mainText}|${suggestion.secondaryText}';
        return seen.add(key);
      })
      .take(5)
      .toList();
}

PlaceSuggestion _suggestionFromPlaceDetails(
  PlaceDetails place, {
  String? title,
  double? originLat,
  double? originLng,
}) {
  const qualityService = AddressQualityService();
  final mainText = title?.trim().isNotEmpty == true
      ? title!.trim()
      : place.name;
  final fallbackTitle = _primaryLabel(place.address);
  final resolvedTitle = mainText.isNotEmpty ? mainText : fallbackTitle;
  final subtitle = qualityService.subtitleFor(
    localityLabel: place.localityLabel,
    address: place.address,
    name: resolvedTitle,
  );
  return PlaceSuggestion(
    placeId: place.placeId,
    description: subtitle.isNotEmpty ? subtitle : resolvedTitle,
    mainText: resolvedTitle,
    secondaryText: subtitle,
    localDetails: place,
    distanceMeters: GeoDistanceUtils.distanceMeters(
      originLat: originLat,
      originLng: originLng,
      destinationLat: place.latitude,
      destinationLng: place.longitude,
    ),
  );
}

PlaceSuggestion _suggestionFromFavoritePlace(
  FavoritePlace favorite, {
  double? originLat,
  double? originLng,
}) {
  final place = PlaceDetails(
    placeId: favorite.placeId ?? '',
    name: favorite.name,
    address: favorite.address,
    latitude: favorite.latitude ?? 0,
    longitude: favorite.longitude ?? 0,
    localityLabel: favorite.address,
  );
  return _suggestionFromPlaceDetails(
    place,
    title: favorite.name,
    originLat: originLat,
    originLng: originLng,
  );
}

bool _matchesQuery(PlaceSuggestion suggestion, String query) {
  final haystack = _normalizeSearchQuery(
    '${suggestion.mainText} ${suggestion.secondaryText} '
    '${suggestion.description}',
  );
  return haystack.contains(query);
}

String _primaryLabel(String value) {
  final index = value.indexOf(',');
  return index > 0 ? value.substring(0, index).trim() : value.trim();
}

String _passengerUserId(Ref ref) {
  final data = ref.read(passengerAuthProvider).userData;
  return passengerAuthUserIdFromData(data)?.toString() ?? 'anonymous';
}

String _normalizeSearchQuery(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
