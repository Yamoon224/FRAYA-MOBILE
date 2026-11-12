import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/services/address_formatter_service.dart';
import '../../core/services/places_service.dart';
import '../../core/data/ci_popular_places.dart';
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
  /// Délai avant d'envoyer une frappe : 300 à 400 ms évitent un appel Google
  /// par lettre tapée.
  static const debounce = Duration(milliseconds: 350);

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
    _debounceTimer = Timer(debounce, () {
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
  // Annule la requête Google en cours dès que la frappe change (le provider est
  // reconstruit à chaque nouvelle requête). Enregistré avant tout `await`.
  final cancelToken = CancelToken();
  ref.onDispose(() {
    if (!cancelToken.isCancelled) cancelToken.cancel('query changed');
  });
  if (query.isEmpty) {
    yield [];
    return;
  }
  final normalizedQuery = normalizePlaceSearchQuery(query);
  if (normalizedQuery.isEmpty) {
    yield [];
    return;
  }

  // Base locale : lieux récents / favoris / enregistrés (Domicile, Travail…)
  // puis lieux populaires d'Abidjan. Aucun appel Google pour ceux-ci.
  final localResults = _withPopularPlaces(
    await localPlaceSuggestions(ref, normalizedQuery),
    normalizedQuery,
  );
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
      : _withPopularPlaces(
          await localPlaceSuggestions(
            ref,
            normalizedQuery,
            originLat: position?.latitude,
            originLng: position?.longitude,
          ),
          normalizedQuery,
          originLat: position?.latitude,
          originLng: position?.longitude,
        );
  if (localResults.isNotEmpty &&
      !samePlaceSuggestionList(localResults, localWithDistance)) {
    yield localWithDistance;
  }

  // Assez de résultats locaux : Google ne sert qu'en secours.
  if (localWithDistance.length >= localSufficientCount) return;

  if (!ref.mounted) return;

  final service = ref.read(placesServiceProvider);
  final remoteResults = await service.getAutocompleteSuggestions(
    normalizedQuery,
    originLat: position?.latitude,
    originLng: position?.longitude,
    cancelToken: cancelToken,
  );
  final merged = mergePlaceSuggestions(localWithDistance, remoteResults);
  if (localWithDistance.isEmpty ||
      !samePlaceSuggestionList(localWithDistance, merged)) {
    yield merged;
  }
}

/// Nombre de résultats locaux à partir duquel on n'interroge pas Google.
const localSufficientCount = 3;

List<PlaceSuggestion> _withPopularPlaces(
  List<PlaceSuggestion> local,
  String query, {
  double? originLat,
  double? originLng,
}) {
  final popular = popularPlaceSuggestions(
    query,
    originLat: originLat,
    originLng: originLng,
  );
  if (popular.isEmpty) return local;
  return mergePlaceSuggestions(local, popular).take(5).toList();
}

/// Détails d'une suggestion déjà présents en cache local, pour afficher la
/// commune exacte. N'appelle JAMAIS Google : un Place Details par suggestion
/// affichée casserait la session d'autocomplete et serait facturé à chaque
/// frappe. Le détail est récupéré une seule fois, à la sélection du lieu.
final suggestionDetailsProvider = FutureProvider.family<PlaceDetails?, String>((
  ref,
  placeId,
) async {
  if (placeId.isEmpty) return null;
  return ref.read(placesServiceProvider).getCachedPlaceDetails(placeId);
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
    // Échec réseau : on garde le lieu déjà choisi au lieu de l'effacer.
    if (details == null) return false;
    state = details.copyWith(
      address: _addressFormatter.normalize(details.address),
    );
    return true;
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
    // Échec réseau : on garde le lieu déjà choisi au lieu de l'effacer.
    if (details == null) return false;
    state = details.copyWith(
      address: _addressFormatter.normalize(details.address),
    );
    return true;
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
