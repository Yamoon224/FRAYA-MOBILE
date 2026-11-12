import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/data/ci_popular_places.dart';
import 'package:fraya_mobile/core/services/places_autocomplete_memory_cache.dart';
import 'package:fraya_mobile/core/services/places_cache_service.dart';
import 'package:fraya_mobile/core/services/places_service.dart';
import 'package:fraya_mobile/core/services/places_session.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();
  });

  group('PlacesSession', () {
    test('reuses one token until the session is closed', () {
      final session = PlacesSession();
      final first = session.current();
      expect(session.current(), first);
      expect(session.close(), first);
    });

    test('a closed token is never reused', () {
      final session = PlacesSession();
      final first = session.current();
      session.close();
      expect(session.current(), isNot(first));
    });

    test('close without a running session returns null', () {
      expect(PlacesSession().close(), isNull);
    });

    test('an expired session starts a new token and is not closable', () {
      var now = DateTime(2026, 11, 12, 10);
      final session = PlacesSession(now: () => now);
      final first = session.current();
      now = now.add(const Duration(minutes: 5));
      expect(session.close(), isNull);
      expect(session.current(), isNot(first));
    });

    test('token looks like a UUID v4', () {
      expect(
        PlacesSession().current(),
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });
  });

  group('PlacesService billing levers', () {
    test('all keystrokes share one token, details closes it', () async {
      final adapter = _CapturingAdapter();
      final service = _service(adapter);

      await service.getAutocompleteSuggestions('ang');
      await service.getAutocompleteSuggestions('angr');
      await service.getAutocompleteSuggestions('angre');
      await service.getPlaceDetails('place_1');

      final tokens = adapter.autocompleteParams
          .map((p) => p['sessiontoken'])
          .toSet();
      expect(tokens, hasLength(1));
      expect(tokens.single, isNotEmpty);
      expect(adapter.detailsParams.single['sessiontoken'], tokens.single);
    });

    test('one-shot lookup sends no token and opens no session', () async {
      final adapter = _CapturingAdapter();
      final service = _service(adapter);

      await service.getAutocompleteSuggestions('aeroport', useSession: false);
      // Une vraie recherche juste après ne doit pas hériter d'une session.
      await service.getPlaceDetails('place_9');

      expect(
        adapter.autocompleteParams.single.containsKey('sessiontoken'),
        isFalse,
      );
      expect(adapter.detailsParams.single.containsKey('sessiontoken'), isFalse);
    });

    test(
      'landmark-style resolution (autocomplete then details) is one session',
      () async {
        final adapter = _CapturingAdapter();
        final service = _service(adapter);

        final suggestions = await service.getAutocompleteSuggestions('cap sud');
        await service.getPlaceDetails(suggestions.first.placeId);

        expect(
          adapter.detailsParams.single['sessiontoken'],
          adapter.autocompleteParams.single['sessiontoken'],
        );
      },
    );

    test('ending a search without selection drops the session', () async {
      final adapter = _CapturingAdapter();
      final service = _service(adapter);

      await service.getAutocompleteSuggestions('cap sud');
      service.endSearchSession();
      await service.getAutocompleteSuggestions('plateau');

      expect(
        adapter.autocompleteParams[0]['sessiontoken'],
        isNot(adapter.autocompleteParams[1]['sessiontoken']),
      );
    });

    test('a new search after selection uses a fresh token', () async {
      final adapter = _CapturingAdapter();
      final service = _service(adapter);

      await service.getAutocompleteSuggestions('angre');
      await service.getPlaceDetails('place_1');
      await service.getAutocompleteSuggestions('plateau');

      expect(
        adapter.autocompleteParams[0]['sessiontoken'],
        isNot(adapter.autocompleteParams[1]['sessiontoken']),
      );
    });

    test('details without a running search sends no token', () async {
      final adapter = _CapturingAdapter();
      final service = _service(adapter);

      await service.getPlaceDetails('place_2');

      expect(adapter.detailsParams.single.containsKey('sessiontoken'), isFalse);
    });

    test(
      'autocomplete is restricted to Côte d\'Ivoire and biased to Abidjan',
      () async {
        final adapter = _CapturingAdapter();
        final service = _service(adapter);

        await service.getAutocompleteSuggestions('cocody');

        final params = adapter.autocompleteParams.single;
        expect(params['components'], 'country:ci');
        expect(
          params['locationbias'],
          startsWith('circle:50000@5.3245,-4.0201'),
        );
      },
    );

    test('bias follows the passenger position when known', () async {
      final adapter = _CapturingAdapter();
      final service = _service(adapter);

      await service.getAutocompleteSuggestions(
        'yopougon',
        originLat: 5.35,
        originLng: -4.08,
      );

      expect(
        adapter.autocompleteParams.single['locationbias'],
        'circle:50000@5.35,-4.08',
      );
    });

    test('details only request address-level fields', () async {
      final adapter = _CapturingAdapter();
      final service = _service(adapter);

      await service.getPlaceDetails('place_3');

      final fields = adapter.detailsParams.single['fields'].toString().split(
        ',',
      );
      for (final expensive in [
        'rating',
        'user_ratings_total',
        'photos',
        'opening_hours',
        'reviews',
        'formatted_phone_number',
        'website',
      ]) {
        expect(fields, isNot(contains(expensive)));
      }
    });

    test(
      'a cancelled request returns no result and no billing retry',
      () async {
        final adapter = _CapturingAdapter(hold: true);
        final service = _service(adapter);
        final token = CancelToken();

        final future = service.getAutocompleteSuggestions(
          'abobo',
          cancelToken: token,
        );
        while (adapter.autocompleteParams.isEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        token.cancel('query changed');

        expect(await future, isEmpty);
        expect(adapter.autocompleteParams, hasLength(1));
      },
    );

    test('nearby search is cached for the same area', () async {
      final adapter = _CapturingAdapter();
      final service = _service(adapter);

      final first = await service.getNearbyPlaces(lat: 5.41234, lng: -3.91234);
      final second = await service.getNearbyPlaces(lat: 5.41301, lng: -3.91301);

      expect(adapter.nearbyCalls, 1);
      expect(second.length, first.length);
    });
  });

  group('Base locale des lieux populaires', () {
    test('finds the airport by alias without accents', () {
      final results = popularPlaceSuggestions('aeroport');
      expect(results.first.mainText, contains('Aéroport'));
      expect(results.first.localDetails, isNotNull);
      expect(results.first.localDetails!.hasValidCoordinates, isTrue);
    });

    test('accents and case are ignored', () {
      expect(popularPlaceSuggestions('ADJAME').first.mainText, 'Adjamé');
      expect(popularPlaceSuggestions('attecoube').first.mainText, 'Attécoubé');
    });

    test('queries under 3 characters never match', () {
      expect(popularPlaceSuggestions('co'), isEmpty);
    });

    test('unknown places return nothing (Google takes over)', () {
      expect(popularPlaceSuggestions('zzzqqq'), isEmpty);
    });

    test('distance is filled when the origin is known', () {
      final result = popularPlaceSuggestions(
        'plateau',
        originLat: 5.3245,
        originLng: -4.0201,
      ).first;
      expect(result.distanceMeters, isNotNull);
    });

    test('ids are stable and prefixed', () {
      for (final p in ciPopularPlaces) {
        expect(p.id, matches(RegExp(r'^[a-z0-9_]+$')));
      }
      expect(
        ciPopularPlaces.map((p) => p.id).toSet().length,
        ciPopularPlaces.length,
      );
    });
  });
}

PlacesService _service(_CapturingAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return PlacesService(
    googleDio: dio,
    cacheService: PlacesCacheService(),
    autocompleteMemoryCache: PlacesAutocompleteMemoryCache(),
    session: PlacesSession(),
  );
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({this.hold = false});

  final bool hold;
  final autocompleteParams = <Map<String, dynamic>>[];
  final detailsParams = <Map<String, dynamic>>[];
  int nearbyCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/autocomplete/')) {
      autocompleteParams.add(Map.of(options.queryParameters));
      if (hold) {
        await cancelFuture;
        throw DioException.requestCancelled(
          requestOptions: options,
          reason: 'cancelled',
        );
      }
      // Résultats distincts par requête pour ne pas dépendre du cache mémoire.
      return _json({
        'status': 'OK',
        'predictions': [
          {
            'place_id': 'place_${autocompleteParams.length}',
            'description': 'Lieu, Cocody, Abidjan',
            'structured_formatting': {
              'main_text': 'Lieu',
              'secondary_text': 'Cocody, Abidjan',
            },
          },
        ],
      });
    }
    if (options.path.contains('/details/')) {
      detailsParams.add(Map.of(options.queryParameters));
      final id = options.queryParameters['place_id'];
      return _json({
        'status': 'OK',
        'result': {
          'place_id': id,
          'name': 'Lieu',
          'formatted_address': 'Rue 1, Cocody, Abidjan',
          'geometry': {
            'location': {'lat': 5.36, 'lng': -3.99},
          },
          'address_components': [
            {
              'long_name': 'Cocody',
              'short_name': 'Cocody',
              'types': ['sublocality_level_1', 'sublocality', 'political'],
            },
            {
              'long_name': 'Abidjan',
              'short_name': 'Abidjan',
              'types': ['locality', 'political'],
            },
          ],
          'types': ['establishment'],
        },
      });
    }
    if (options.path.contains('/nearbysearch/')) {
      nearbyCalls++;
      return _json({
        'status': 'OK',
        'results': [
          {
            'place_id': 'near_1',
            'name': 'Proche',
            'vicinity': 'Cocody',
            'geometry': {
              'location': {'lat': 5.41, 'lng': -3.91},
            },
            'types': ['point_of_interest'],
          },
        ],
      });
    }
    return _json({'status': 'NOT_FOUND'}, statusCode: 404);
  }

  @override
  void close({bool force = false}) {}

  ResponseBody _json(Map<String, dynamic> body, {int statusCode = 200}) {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );
  }
}
