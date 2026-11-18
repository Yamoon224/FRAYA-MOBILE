import '../../core/data/ci_popular_places.dart' show foldSearchText;
import '../../core/models/places_models.dart';

String normalizePlaceSearchQuery(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

List<PlaceSuggestion> mergePlaceSuggestions(
  List<PlaceSuggestion> localResults,
  List<PlaceSuggestion> remoteResults,
) {
  final seen = <String>{};
  final merged = <PlaceSuggestion>[];
  for (final suggestion in [...localResults, ...remoteResults]) {
    final key = placeSuggestionKey(suggestion);
    if (seen.add(key)) merged.add(suggestion);
  }
  return merged;
}

bool samePlaceSuggestionList(
  List<PlaceSuggestion> left,
  List<PlaceSuggestion> right,
) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (placeSuggestionKey(left[i]) != placeSuggestionKey(right[i])) {
      return false;
    }
    if (left[i].distanceMeters != right[i].distanceMeters) return false;
  }
  return true;
}

String placeSuggestionKey(PlaceSuggestion suggestion) {
  if (suggestion.placeId.isNotEmpty) return 'id:${suggestion.placeId}';
  final text = [
    suggestion.mainText,
    suggestion.secondaryText,
    suggestion.description,
  ].join(' ');
  return 'text:${normalizePlaceSearchQuery(text)}';
}

/// Nombre de suggestions locales dont le NOM correspond à la recherche. Une correspondance sur la seule
/// commune (« Cocody » dans l'adresse) ne prouve pas que le lieu cherché est dans la liste locale : elle ne
/// doit pas empêcher d'interroger Google.
int strongLocalMatchCount(List<PlaceSuggestion> local, String query) {
  final q = foldSearchText(query);
  if (q.isEmpty) return 0;
  return local.where((s) => foldSearchText(s.mainText).contains(q)).length;
}
