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

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();
  });

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

  test('three characters without local hit call normal autocomplete', () async {
    final service = _CountingPlacesService();
    final container = ProviderContainer(
      overrides: [
        searchQueryProvider.overrideWithValue('ang'),
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
          searchQueryProvider.overrideWithValue('neo'),
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
      expect(service.lastBypassCache, isTrue);
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
          searchQueryProvider.overrideWithValue('res'),
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
      expect(service.lastBypassCache, isTrue);
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
          searchQueryProvider.overrideWithValue('res'),
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
      expect(service.lastBypassCache, isTrue);
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
        searchQueryProvider.overrideWithValue('res'),
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
    expect(service.lastBypassCache, isTrue);
    expect(events.last, hasLength(1));
    expect(events.last.single.mainText, 'Restaurant local');
    expect(events.last.single.localDetails, isNotNull);
  });

  test('three characters with local hit bypass autocomplete cache', () async {
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
        searchQueryProvider.overrideWithValue('res'),
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
    expect(service.lastBypassCache, isTrue);
  });

  test(
    'three characters without local hit keep normal autocomplete cache flow',
    () async {
      final service = _CountingPlacesService();
      final container = ProviderContainer(
        overrides: [
          searchQueryProvider.overrideWithValue('res'),
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
