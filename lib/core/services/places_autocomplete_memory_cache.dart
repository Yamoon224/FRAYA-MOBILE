import '../models/places_models.dart';

class PlacesAutocompleteMemoryCache {
  PlacesAutocompleteMemoryCache({
    DateTime Function()? now,
    this.ttl = const Duration(minutes: 10),
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Duration ttl;
  final Map<String, _AutocompleteCacheEntry> _entries = {};

  List<PlaceSuggestion>? read(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (_now().isAfter(entry.expiresAt)) {
      _entries.remove(key);
      return null;
    }
    return entry.suggestions;
  }

  void save(String key, List<PlaceSuggestion> suggestions) {
    _entries[key] = _AutocompleteCacheEntry(
      suggestions: suggestions,
      expiresAt: _now().add(ttl),
    );
  }

  void clear() => _entries.clear();
}

class _AutocompleteCacheEntry {
  const _AutocompleteCacheEntry({
    required this.suggestions,
    required this.expiresAt,
  });

  final List<PlaceSuggestion> suggestions;
  final DateTime expiresAt;
}
