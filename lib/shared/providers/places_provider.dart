import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/services/address_formatter_service.dart';
import '../../core/services/places_service.dart';
import '../../core/models/places_models.dart';
import 'location_provider.dart';
import 'places_local_suggestions.dart';
import 'places_suggestion_utils.dart';

part 'places_provider.g.dart';

@riverpod
PlacesService placesService(Ref ref) {
  return PlacesService();
}

enum SearchType { pickup, destination }

@Riverpod(keepAlive: true)
class ActiveSearchType extends _$ActiveSearchType {
  @override
  SearchType build() => SearchType.destination;

  void setType(SearchType type) => state = type;
}

@riverpod
class SearchQuery extends _$SearchQuery {
  Timer? _debounceTimer;

  @override
  String build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return '';
  }

  void updateQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      state = query;
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    state = '';
  }
}

@riverpod
Stream<List<PlaceSuggestion>> placeSuggestions(Ref ref) async* {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    yield [];
    return;
  }
  final normalizedQuery = normalizePlaceSearchQuery(query);
  if (normalizedQuery.isEmpty) {
    yield [];
    return;
  }

  final localResults = await localPlaceSuggestions(ref, normalizedQuery);
  if (localResults.isNotEmpty) {
    yield localResults;
  }

  if (normalizedQuery.length < PlacesService.minAutocompleteQueryLength) {
    if (localResults.isNotEmpty) {
      final position = await ref.read(passengerLocationSnapshotProvider.future);
      final localWithDistance = await localPlaceSuggestions(
        ref,
        normalizedQuery,
        originLat: position?.latitude,
        originLng: position?.longitude,
      );
      if (!samePlaceSuggestionList(localResults, localWithDistance)) {
        yield localWithDistance;
      }
    }
    if (localResults.isEmpty) yield [];
    return;
  }

  // `read` (pas `watch`) : la position sert d'origine pour la distance mais ne
  // doit pas relancer la recherche à chaque tick GPS.
  final position = await ref.read(passengerLocationSnapshotProvider.future);
  final localWithDistance = localResults.isEmpty
      ? localResults
      : await localPlaceSuggestions(
          ref,
          normalizedQuery,
          originLat: position?.latitude,
          originLng: position?.longitude,
        );
  if (localResults.isNotEmpty &&
      !samePlaceSuggestionList(localResults, localWithDistance)) {
    yield localWithDistance;
  }

  final service = ref.read(placesServiceProvider);
  final remoteResults = await service.getAutocompleteSuggestions(
    normalizedQuery,
    originLat: position?.latitude,
    originLng: position?.longitude,
    bypassCache:
        normalizedQuery.length >=
            PlacesService.forceAutocompleteRefreshQueryLength &&
        localWithDistance.isNotEmpty,
  );
  final merged = mergePlaceSuggestions(localWithDistance, remoteResults);
  if (localWithDistance.isEmpty ||
      !samePlaceSuggestionList(localWithDistance, merged)) {
    yield merged;
  }
}

/// Résout les détails d'une suggestion (par placeId) pour récupérer la commune
/// exacte absente du texte d'autocomplete. Provider *family* manuel (non codegen)
/// et non auto-dispose : un placeId déjà résolu reste en cache et n'est pas
/// re-fetché quand la liste se reconstruit à chaque frappe.
final suggestionDetailsProvider = FutureProvider.family<PlaceDetails?, String>((
  ref,
  placeId,
) async {
  if (placeId.isEmpty) return null;
  final service = ref.read(placesServiceProvider);
  return service.getPlaceDetails(placeId);
});

@Riverpod(keepAlive: true)
class SelectedPickup extends _$SelectedPickup {
  static const _addressFormatter = AddressFormatterService();

  @override
  PlaceDetails? build() {
    return null;
  }

  Future<bool> selectPlace(String placeId) async {
    final service = ref.read(placesServiceProvider);
    final details = await service.getPlaceDetails(placeId);
    state = details?.copyWith(
      address: _addressFormatter.normalize(details.address),
    );
    return details != null;
  }

  void setPlace(PlaceDetails details) {
    state = details.copyWith(
      address: _addressFormatter.normalize(details.address),
    );
  }

  void clear() {
    state = null;
  }
}

@Riverpod(keepAlive: true)
class SelectedDestination extends _$SelectedDestination {
  static const _addressFormatter = AddressFormatterService();

  @override
  PlaceDetails? build() {
    return null;
  }

  Future<bool> selectPlace(String placeId) async {
    final service = ref.read(placesServiceProvider);
    final details = await service.getPlaceDetails(placeId);
    state = details?.copyWith(
      address: _addressFormatter.normalize(details.address),
    );
    return details != null;
  }

  void setPlace(PlaceDetails details) {
    state = details.copyWith(
      address: _addressFormatter.normalize(details.address),
    );
  }

  void clear() {
    state = null;
  }
}

int _landmarkPriority(PlaceDetails p) {
  const loisirs = {
    'park',
    'amusement_park',
    'tourist_attraction',
    'stadium',
    'museum',
    'aquarium',
    'zoo',
    'movie_theater',
    'spa',
    'gym',
    'bowling_alley',
    'casino',
    'night_club',
  };
  const restos = {
    'restaurant',
    'cafe',
    'bar',
    'bakery',
    'meal_takeaway',
    'meal_delivery',
    'food',
  };
  const hopitaux = {
    'hospital',
    'doctor',
    'dentist',
    'pharmacy',
    'health',
    'physiotherapist',
  };
  const marches = {
    'supermarket',
    'shopping_mall',
    'grocery_or_supermarket',
    'store',
    'market',
    'convenience_store',
    'department_store',
  };

  if (p.types.any(loisirs.contains)) return 1;
  if (p.types.any(restos.contains)) return 2;
  if (p.types.any(hopitaux.contains)) return 3;
  if (p.types.any(marches.contains)) return 4;
  return 5;
}

@riverpod
Future<List<PlaceDetails>> nearbyLandmarks(Ref ref) async {
  final service = ref.read(placesServiceProvider);
  final location = await ref.watch(passengerLocationSnapshotProvider.future);
  final results = await service.getNearbyPlaces(
    lat: location?.latitude ?? 5.3245,
    lng: location?.longitude ?? -4.0201,
  );

  return [...results]
    ..sort((a, b) => _landmarkPriority(a).compareTo(_landmarkPriority(b)));
}
