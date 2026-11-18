import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/services/places_service.dart';
import 'package:fraya_mobile/core/services/recent_places_service.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/features/passenger/profile/widgets/saved_places/simple_search_sheet.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Pause avant l'appel Google : annulée dans les tests (les cas qui la vérifient la rétablissent).
  final defaultGoogleDelay = placesGoogleExtraDelay;

  setUp(() async {
    placesGoogleExtraDelay = Duration.zero;
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();
  });

  tearDown(() => placesGoogleExtraDelay = defaultGoogleDelay);

  test(
    'short queries do not call autocomplete when local results miss',
    () async {
      final service = _CountingPlacesService();
      var locationReads = 0;
      final container = ProviderContainer(
        overrides: [
          searchQueryProvider.overrideWithValue('an'),
          placesServiceProvider.overrideWith((ref) => service),
          passengerLocationSnapshotProvider.overrideWith((ref) async {
            locationReads++;
            return null;
          }),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        placeSuggestionsProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      final suggestions = await container.read(placeSuggestionsProvider.future);

      expect(suggestions, isEmpty);
      expect(service.autocompleteCalls, 0);
      expect(locationReads, 0);
    },
  );

  test('five characters without local hit call normal autocomplete', () async {
    final service = _CountingPlacesService();
    final container = ProviderContainer(
      overrides: [
        searchQueryProvider.overrideWithValue('zzzzz'),
        placesServiceProvider.overrideWith((ref) => service),
        passengerLocationSnapshotProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(placeSuggestionsProvider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(placeSuggestionsProvider.future);

    expect(service.autocompleteCalls, 1);
    expect(service.lastBypassCache, isFalse);
  });

  test(
    'local recent results are returned before Google autocomplete',
    () async {
      await RecentPlacesService('anonymous').add(
        const PlaceDetails(
          placeId: 'recent_1',
          name: 'Neobureau',
          address: 'Angre 8eme tranche, Cocody',
          latitude: 5.39,
          longitude: -3.99,
          localityLabel: 'Angre 8eme tranche, Cocody',
        ),
      );
      final service = _CountingPlacesService();
      var locationReads = 0;
      final container = ProviderContainer(
        overrides: [
          searchQueryProvider.overrideWithValue('neobu'),
          placesServiceProvider.overrideWith((ref) => service),
          passengerLocationSnapshotProvider.overrideWith((ref) async {
            locationReads++;
            return null;
          }),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        placeSuggestionsProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      final suggestions = await container.read(placeSuggestionsProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(suggestions.single.placeId, 'recent_1');
      expect(suggestions.single.localDetails, isNotNull);
      expect(suggestions.single.distanceMeters, isNull);
      expect(service.autocompleteCalls, 1);
      expect(service.lastBypassCache, isFalse);
      expect(locationReads, 1);
    },
  );

  test(
    'local result gets distance when passenger position is available',
    () async {
      await RecentPlacesService('anonymous').add(
        const PlaceDetails(
          placeId: 'nearby_1',
          name: 'Restaurant proche',
          address: 'Rue proche, Cocody',
          latitude: 5.001,
          longitude: -4,
          localityLabel: 'Rue proche, Cocody',
        ),
      );
      final service = _CountingPlacesService(suggestions: []);
      final container = ProviderContainer(
        overrides: [
          searchQueryProvider.overrideWithValue('resta'),
          placesServiceProvider.overrideWith((ref) => service),
          passengerLocationSnapshotProvider.overrideWith(
            (ref) async => _position(latitude: 5, longitude: -4),
          ),
        ],
      );
      addTearDown(container.dispose);

      final events = <List<PlaceSuggestion>>[];
      final subscription = container.listen(
        placeSuggestionsProvider,
        (_, next) => next.whenData(events.add),
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await container.read(placeSuggestionsProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(events.last.single.distanceMeters, inInclusiveRange(100, 120));
      expect(service.autocompleteCalls, 1);
      expect(service.lastBypassCache, isFalse);
    },
  );

  test(
    'local results do not stop autocomplete after min query length',
    () async {
      await RecentPlacesService('anonymous').add(
        const PlaceDetails(
          placeId: 'local_restaurant',
          name: 'Restaurant local',
          address: 'Rue des Jardins, Cocody',
          latitude: 5.39,
          longitude: -3.99,
          localityLabel: 'Rue des Jardins, Cocody',
        ),
      );
      final service = _CountingPlacesService(
        suggestions: [
          PlaceSuggestion(
            placeId: 'google_restaurant',
            description: 'Restaurant Google, Cocody',
            mainText: 'Restaurant Google',
            secondaryText: 'Cocody',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          searchQueryProvider.overrideWithValue('resta'),
          placesServiceProvider.overrideWith((ref) => service),
          passengerLocationSnapshotProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      final events = <List<PlaceSuggestion>>[];
      final subscription = container.listen(
        placeSuggestionsProvider,
        (_, next) => next.whenData(events.add),
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final first = await container.read(placeSuggestionsProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(first.single.placeId, 'local_restaurant');
      expect(service.autocompleteCalls, 1);
      expect(service.lastBypassCache, isFalse);
      expect(events.last.map((s) => s.placeId), [
        'local_restaurant',
        'google_restaurant',
      ]);
    },
  );

  test('local duplicate wins over autocomplete duplicate', () async {
    await RecentPlacesService('anonymous').add(
      const PlaceDetails(
        placeId: 'same_place',
        name: 'Restaurant local',
        address: 'Rue locale, Cocody',
        latitude: 5.39,
        longitude: -3.99,
        localityLabel: 'Rue locale, Cocody',
      ),
    );
    final service = _CountingPlacesService(
      suggestions: [
        PlaceSuggestion(
          placeId: 'same_place',
          description: 'Restaurant Google, Cocody',
          mainText: 'Restaurant Google',
          secondaryText: 'Cocody',
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        searchQueryProvider.overrideWithValue('resta'),
        placesServiceProvider.overrideWith((ref) => service),
        passengerLocationSnapshotProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);

    final events = <List<PlaceSuggestion>>[];
    final subscription = container.listen(
      placeSuggestionsProvider,
      (_, next) => next.whenData(events.add),
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(placeSuggestionsProvider.future);
    await Future<void>.delayed(Duration.zero);

    expect(service.autocompleteCalls, 1);
    expect(service.lastBypassCache, isFalse);
    expect(events.last, hasLength(1));
    expect(events.last.single.mainText, 'Restaurant local');
    expect(events.last.single.localDetails, isNotNull);
  });

  test(
    'five characters with a local hit keep the autocomplete cache (no forced refresh)',
    () async {
      await RecentPlacesService('anonymous').add(
        const PlaceDetails(
          placeId: 'local_restaurant',
          name: 'Restaurant local',
          address: 'Rue des Jardins, Cocody',
          latitude: 5.39,
          longitude: -3.99,
          localityLabel: 'Rue des Jardins, Cocody',
        ),
      );
      final service = _CountingPlacesService();
      final container = ProviderContainer(
        overrides: [
          searchQueryProvider.overrideWithValue('resta'),
          placesServiceProvider.overrideWith((ref) => service),
          passengerLocationSnapshotProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        placeSuggestionsProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container.read(placeSuggestionsProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(service.autocompleteCalls, 1);
      expect(service.lastBypassCache, isFalse);
    },
  );

  test(
    'five characters without local hit keep normal autocomplete cache flow',
    () async {
      final service = _CountingPlacesService();
      final container = ProviderContainer(
        overrides: [
          searchQueryProvider.overrideWithValue('resta'),
          placesServiceProvider.overrideWith((ref) => service),
          passengerLocationSnapshotProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        placeSuggestionsProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container.read(placeSuggestionsProvider.future);

      expect(service.autocompleteCalls, 1);
      expect(service.lastBypassCache, isFalse);
    },
  );

  test('enough local results (3+) skip Google entirely', () async {
    for (final n in ['Resto A', 'Resto B', 'Resto C']) {
      await RecentPlacesService('anonymous').add(
        PlaceDetails(
          placeId: 'recent_$n',
          name: n,
          address: 'Rue $n, Cocody',
          latitude: 5.39,
          longitude: -3.99,
          localityLabel: 'Rue $n, Cocody',
        ),
      );
    }
    final service = _CountingPlacesService();
    final container = ProviderContainer(
      overrides: [
        searchQueryProvider.overrideWithValue('resto'),
        placesServiceProvider.overrideWith((ref) => service),
        passengerLocationSnapshotProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(placeSuggestionsProvider, (_, _) {});
    addTearDown(subscription.close);

    final suggestions = await container.read(placeSuggestionsProvider.future);
    await Future<void>.delayed(Duration.zero);

    expect(suggestions, hasLength(3));
    expect(service.autocompleteCalls, 0);
  });

  test('popular Abidjan places are served locally before Google', () async {
    final service = _CountingPlacesService();
    final container = ProviderContainer(
      overrides: [
        searchQueryProvider.overrideWithValue('aeroport'),
        placesServiceProvider.overrideWith((ref) => service),
        passengerLocationSnapshotProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(placeSuggestionsProvider, (_, _) {});
    addTearDown(subscription.close);

    final first = await container.read(placeSuggestionsProvider.future);

    expect(first.first.placeId, startsWith('local_ci_'));
    expect(first.first.localDetails, isNotNull);
  });

  test('local search is quick, Google waits for a longer pause', () {
    // Local (gratuit) : réponse rapide. Google (payant) : débounce + pause supplémentaire ≈ 0,7 s.
    expect(SearchQuery.debounce.inMilliseconds, inInclusiveRange(200, 300));
    expect(
      (SearchQuery.debounce + defaultGoogleDelay).inMilliseconds,
      inInclusiveRange(600, 900),
    );
  });

  test(
    '3 and 4 characters are answered locally only, never by Google',
    () async {
      await RecentPlacesService('anonymous').add(
        const PlaceDetails(
          placeId: 'local_restaurant',
          name: 'Restaurant local',
          address: 'Rue des Jardins, Cocody',
          latitude: 5.39,
          longitude: -3.99,
          localityLabel: 'Rue des Jardins, Cocody',
        ),
      );
      for (final query in ['res', 'rest']) {
        final service = _CountingPlacesService();
        final container = ProviderContainer(
          overrides: [
            searchQueryProvider.overrideWithValue(query),
            placesServiceProvider.overrideWith((ref) => service),
            passengerLocationSnapshotProvider.overrideWith((ref) async => null),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          placeSuggestionsProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);

        final suggestions = await container.read(
          placeSuggestionsProvider.future,
        );

        expect(suggestions.single.placeId, 'local_restaurant', reason: query);
        expect(service.autocompleteCalls, 0, reason: query);
      }
    },
  );

  test('local matches on the commune only do not replace Google', () async {
    // Trois récents situés à Cocody, mais dont aucun NOM ne correspond à « cocod ».
    for (final n in ['Alpha', 'Beta', 'Gamma']) {
      await RecentPlacesService('anonymous').add(
        PlaceDetails(
          placeId: 'recent_$n',
          name: n,
          address: 'Rue $n, Cocody',
          latitude: 5.39,
          longitude: -3.99,
          localityLabel: 'Rue $n, Cocody',
        ),
      );
    }
    final service = _CountingPlacesService();
    final container = ProviderContainer(
      overrides: [
        searchQueryProvider.overrideWithValue('cocod'),
        placesServiceProvider.overrideWith((ref) => service),
        passengerLocationSnapshotProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(placeSuggestionsProvider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(placeSuggestionsProvider.future);
    await Future<void>.delayed(Duration.zero);

    expect(service.autocompleteCalls, 1);
  });

  test('typing again during the pause cancels the paid call', () async {
    placesGoogleExtraDelay = const Duration(milliseconds: 120);
    final service = _CountingPlacesService();
    final container = ProviderContainer(
      overrides: [
        searchQueryProvider.overrideWithValue('zzzzz'),
        placesServiceProvider.overrideWith((ref) => service),
        passengerLocationSnapshotProvider.overrideWith((ref) async => null),
      ],
    );
    final subscription = container.listen(placeSuggestionsProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // Le passager a continué à taper : la recherche est abandonnée.
    subscription.close();
    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(service.autocompleteCalls, 0);
  });

  test(
    'recents keep 30 places for search but the home list shows 10',
    () async {
      final recents = RecentPlacesService('anonymous');
      for (var i = 0; i < 35; i++) {
        await recents.add(
          PlaceDetails(
            placeId: 'p$i',
            name: 'Lieu $i',
            address: 'Rue $i, Cocody',
            latitude: 5.3 + i / 1000,
            longitude: -4,
          ),
        );
      }

      expect((await recents.getAll()).length, RecentPlacesService.maxItems);
      expect(RecentPlacesService.maxItems, 30);
      expect(RecentPlacesService.displayItems, 10);
    },
  );

  test('details of a suggestion tile never hit the network', () async {
    final service = _CountingPlacesService();
    final container = ProviderContainer(
      overrides: [placesServiceProvider.overrideWith((ref) => service)],
    );
    addTearDown(container.dispose);

    await container.read(suggestionDetailsProvider('google_9').future);

    expect(service.detailsCalls, 0);
  });

  testWidgets('SimpleSearchSheet uses localDetails without details call', (
    tester,
  ) async {
    await RecentPlacesService('anonymous').add(
      const PlaceDetails(
        placeId: 'local_restaurant',
        name: 'Restaurant local',
        address: 'Rue des Jardins, Cocody',
        latitude: 5.39,
        longitude: -3.99,
        localityLabel: 'Rue des Jardins, Cocody',
      ),
    );
    final service = _CountingPlacesService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchQueryProvider.overrideWithValue('resta'),
          placesServiceProvider.overrideWith((ref) => service),
          passengerLocationSnapshotProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: Scaffold(body: SimpleSearchSheet())),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Restaurant local'));
    await tester.pumpAndSettle();

    expect(service.detailsCalls, 0);
  });
}

class _CountingPlacesService extends PlacesService {
  _CountingPlacesService({this.suggestions});

  final List<PlaceSuggestion>? suggestions;
  int autocompleteCalls = 0;
  int detailsCalls = 0;
  bool? lastBypassCache;

  @override
  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
    String query, {
    String? sessionToken,
    String language = 'fr',
    String components = 'country:ci',
    double? originLat,
    double? originLng,
    bool bypassCache = false,
    Object? cancelToken,
    bool useSession = true,
  }) async {
    autocompleteCalls++;
    lastBypassCache = bypassCache;
    return suggestions ??
        [
          PlaceSuggestion(
            placeId: 'google_1',
            description: 'Google result',
            mainText: 'Google',
            secondaryText: 'Abidjan',
          ),
        ];
  }

  @override
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String language = 'fr',
  }) async {
    detailsCalls++;
    return null;
  }
}

Position _position({required double latitude, required double longitude}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: DateTime(2026, 7, 13, 12),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}
