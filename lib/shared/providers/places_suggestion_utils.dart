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
