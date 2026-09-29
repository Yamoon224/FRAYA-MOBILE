import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/services/places_autocomplete_memory_cache.dart';

void main() {
  test('returns session suggestions until ttl expires', () {
    var now = DateTime(2026, 1, 1, 12);
    final cache = PlacesAutocompleteMemoryCache(now: () => now);
    final suggestions = [
      PlaceSuggestion(
        placeId: 'place_1',
        description: 'Angre 8eme tranche, Cocody',
        mainText: 'Angre',
        secondaryText: 'Angre 8eme tranche, Cocody',
      ),
    ];

    cache.save('angre|fr|ci', suggestions);

    expect(cache.read('angre|fr|ci'), suggestions);

    now = now.add(const Duration(minutes: 11));

    expect(cache.read('angre|fr|ci'), isNull);
  });
}
