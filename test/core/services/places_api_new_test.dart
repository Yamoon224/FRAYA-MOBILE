import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/maps_usage_tracker.dart';
import 'package:fraya_mobile/core/services/places_api_new_client.dart';
import 'package:fraya_mobile/core/services/places_autocomplete_memory_cache.dart';
import 'package:fraya_mobile/core/services/places_cache_service.dart';
import 'package:fraya_mobile/core/services/places_service.dart';
import 'package:fraya_mobile/core/services/places_session.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Call {
  _Call(this.options);
  final RequestOptions options;
  String get method => options.method;
  String get path => options.uri.path;
  Map<String, dynamic> get query => options.uri.queryParameters;
  dynamic get body => options.data;
  String? header(String name) => options.headers[name]?.toString();
}

/// Simule Google : routes « new » (places.googleapis.com) et « legacy » (maps.googleapis.com).
class _GoogleAdapter implements HttpClientAdapter {
  _GoogleAdapter({this.newStatus = 200});

  /// Statut renvoyé par Places API (New) (200, 403, 404…).
  int newStatus;
  final calls = <_Call>[];

  Iterable<_Call> get newCalls =>
      calls.where((c) => c.options.uri.host == 'places.googleapis.com');
  Iterable<_Call> get legacyCalls =>
      calls.where((c) => c.options.uri.host == 'maps.googleapis.com');

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(_Call(options));
    final uri = options.uri;
    if (uri.host == 'places.googleapis.com') {
      if (newStatus != 200) {
        return _json({
          'error': {'code': newStatus, 'status': 'PERMISSION_DENIED'},
        }, newStatus);
      }
      if (uri.path.contains(':autocomplete')) {
        return _json({
          'suggestions': [
            {
              'placePrediction': {
                'placeId': 'place_1',
                'text': {'text': 'Centre commercial Cap Sud, Marcory, Abidjan'},
                'structuredFormat': {
                  'mainText': {'text': 'Centre commercial Cap Sud'},
                  'secondaryText': {'text': 'Marcory, Abidjan'},
                },
                'types': ['shopping_mall', 'establishment'],
                'distanceMeters': 1200,
              },
            },
            // Une « requête de lieu » : doit être ignorée.
            {
              'queryPrediction': {
                'text': {'text': 'cap sud'},
              },
            },
          ],
        }, 200);
      }
      return _json({
        'id': 'place_1',
        'formattedAddress': "Bd de Marseille, Marcory, Abidjan, Côte d'Ivoire",
        'adrFormatAddress':
            '<span class="street-address">Bd de Marseille</span>',
        'shortFormattedAddress': 'Bd de Marseille, Marcory',
        'location': {'latitude': 5.279, 'longitude': -3.989},
        'types': ['shopping_mall'],
        'displayName': {'text': 'Cap Sud (nom Google)'},
        'addressComponents': [
          {
            'longText': 'Marcory',
            'shortText': 'Marcory',
            'types': ['sublocality_level_1', 'sublocality', 'political'],
          },
          {
            'longText': 'Abidjan',
            'shortText': 'Abidjan',
            'types': ['locality', 'political'],
          },
        ],
      }, 200);
    }
    // Ancienne API
    if (uri.path.contains('/autocomplete/')) {
      return _json({
        'status': 'OK',
        'predictions': [
          {
            'place_id': 'legacy_1',
            'description': 'Legacy, Cocody, Abidjan',
            'structured_formatting': {
              'main_text': 'Legacy',
              'secondary_text': 'Cocody, Abidjan',
            },
          },
        ],
      }, 200);
    }
    return _json({
      'status': 'OK',
      'result': {
        'place_id': 'legacy_1',
        'name': 'Legacy',
        'formatted_address': "Rue 1, Cocody, Abidjan, Côte d'Ivoire",
        'geometry': {
          'location': {'lat': 5.35, 'lng': -3.98},
        },
        'address_components': [
          {
            'long_name': 'Cocody',
            'short_name': 'Cocody',
            'types': ['sublocality_level_1'],
          },
        ],
        'types': ['establishment'],
      },
    }, 200);
  }

  ResponseBody _json(Map<String, dynamic> body, int status) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

PlacesService _service(_GoogleAdapter adapter, {PlacesSession? session}) {
  final dio = Dio()..httpClientAdapter = adapter;
  return PlacesService(
    googleDio: dio,
    cacheService: PlacesCacheService(),
    autocompleteMemoryCache: PlacesAutocompleteMemoryCache(),
    session: session ?? PlacesSession(),
    useNewApi: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(
    () => dotenv.loadFromString(envString: 'GOOGLE_PLACES_API_KEY=test-key'),
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();
    PlacesApiNewClient.debugReset();
    PlacesService.debugResetPredictionNames();
  });

  group('Autocomplétion', () {
    test('envoie une requête conforme à Places API (New)', () async {
      final adapter = _GoogleAdapter();
      final service = _service(adapter);

      await service.getAutocompleteSuggestions(
        'cap sud',
        originLat: 5.3,
        originLng: -4.0,
      );

      final call = adapter.newCalls.single;
      expect(call.method, 'POST');
      expect(call.path, '/v1/places:autocomplete');
      expect(call.header('X-Goog-Api-Key'), 'test-key');
      expect(
        call.header('X-Goog-FieldMask'),
        contains('placePrediction.placeId'),
      );
      final body = call.body as Map;
      expect(body['input'], 'cap sud');
      expect(body['languageCode'], 'fr');
      expect(body['includedRegionCodes'], ['ci']);
      expect(body['sessionToken'], isNotEmpty);
      expect(body['origin'], {'latitude': 5.3, 'longitude': -4.0});
      final circle = (body['locationBias'] as Map)['circle'] as Map;
      expect(circle['radius'], lessThanOrEqualTo(50000));
      expect(adapter.legacyCalls, isEmpty);
    });

    test(
      "convertit la réponse sans rien changer pour le reste de l'app",
      () async {
        final service = _service(_GoogleAdapter());

        final suggestions = await service.getAutocompleteSuggestions('cap sud');

        expect(suggestions, hasLength(1)); // la requête de lieu est ignorée
        expect(suggestions.single.placeId, 'place_1');
        expect(suggestions.single.mainText, 'Centre commercial Cap Sud');
        expect(suggestions.single.distanceMeters, 1200);
        expect(suggestions.single.secondaryText, contains('Marcory'));
      },
    );
  });

  group('Détails du lieu', () {
    test(
      'après une autocomplétion : champs Essentials, sans le nom, même session',
      () async {
        final adapter = _GoogleAdapter();
        final service = _service(adapter);

        await service.getAutocompleteSuggestions('cap sud');
        final autocompleteToken =
            (adapter.newCalls.first.body as Map)['sessionToken'];
        final details = await service.getPlaceDetails('place_1');

        final call = adapter.newCalls.last;
        expect(call.method, 'GET');
        expect(call.path, '/v1/places/place_1');
        final mask = call.header('X-Goog-FieldMask')!;
        expect(mask, isNot(contains('displayName'))); // palier Essentials
        expect(mask, contains('location'));
        // La session d'autocomplétion est bien close par cet appel.
        expect(call.query['sessionToken'], autocompleteToken);

        expect(details, isNotNull);
        expect(
          details!.name,
          'Centre commercial Cap Sud',
        ); // nom de l'autocomplétion
        expect(details.latitude, 5.279);
        expect(details.longitude, -3.989);
        expect(details.address, isNotEmpty);
        expect(details.types, ['shopping_mall']);
        expect(adapter.legacyCalls, isEmpty);
      },
    );

    test(
      'sans nom connu : le nom est demandé (aucune perte par rapport à avant)',
      () async {
        final adapter = _GoogleAdapter();
        final service = _service(adapter);

        final details = await service.getPlaceDetails('place_1');

        expect(
          adapter.newCalls.single.header('X-Goog-FieldMask'),
          contains('displayName'),
        );
        expect(details!.name, 'Cap Sud (nom Google)');
      },
    );

    test('un lieu déjà vu vient du cache : aucun appel', () async {
      final adapter = _GoogleAdapter();
      final service = _service(adapter);

      await service.getPlaceDetails('place_1');
      await service.getPlaceDetails('place_1');

      expect(adapter.newCalls, hasLength(1));
    });
  });

  group("Repli sur l'ancienne API", () {
    test(
      "403 (API non activée) : l'ancienne API répond, puis la nouvelle est mise de côté",
      () async {
        final adapter = _GoogleAdapter(newStatus: 403);
        final service = _service(adapter);

        final first = await service.getAutocompleteSuggestions('cap sud');
        expect(first.single.placeId, 'legacy_1');
        expect(adapter.newCalls, hasLength(1));
        expect(adapter.legacyCalls, hasLength(1));

        // Deuxième recherche : la nouvelle API n'est même plus essayée.
        await service.getAutocompleteSuggestions('cocody plateau');
        expect(adapter.newCalls, hasLength(1));
        expect(adapter.legacyCalls, hasLength(2));
      },
    );

    test('404 sur les détails : repli sans couper la nouvelle API', () async {
      final adapter = _GoogleAdapter(newStatus: 404);
      final service = _service(adapter);

      final details = await service.getPlaceDetails('place_x');

      expect(details!.placeId, 'legacy_1');
      expect(adapter.legacyCalls, hasLength(1));

      adapter.newStatus = 200;
      await service.getAutocompleteSuggestions('cap sud');
      expect(adapter.newCalls.last.path, '/v1/places:autocomplete');
    });

    test('la nouvelle API peut être coupée par configuration', () async {
      final adapter = _GoogleAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final service = PlacesService(
        googleDio: dio,
        cacheService: PlacesCacheService(),
        autocompleteMemoryCache: PlacesAutocompleteMemoryCache(),
        session: PlacesSession(),
        useNewApi: false,
      );

      await service.getAutocompleteSuggestions('cap sud');

      expect(adapter.newCalls, isEmpty);
      expect(adapter.legacyCalls, hasLength(1));
    });
  });

  group('Suivi de consommation', () {
    RequestOptions request(
      String url, {
      Map<String, dynamic>? headers,
      String method = 'GET',
    }) => RequestOptions(path: url, method: method, headers: headers);

    test(
      'autocomplétion et détails sont classés, le palier Essentials à part',
      () {
        expect(
          MapsUsageInterceptor.classifyRequest(
            request(
              'https://places.googleapis.com/v1/places:autocomplete',
              method: 'POST',
            ),
          ),
          MapsService.placesAutocomplete,
        );
        expect(
          MapsUsageInterceptor.classifyRequest(
            request(
              'https://places.googleapis.com/v1/places/abc',
              headers: {
                'X-Goog-FieldMask': PlacesApiNewClient.essentialsDetailsMask,
              },
            ),
          ),
          MapsService.placeDetailsEssentials,
        );
        expect(
          MapsUsageInterceptor.classifyRequest(
            request(
              'https://places.googleapis.com/v1/places/abc',
              headers: {'X-Goog-FieldMask': 'id,displayName'},
            ),
          ),
          MapsService.placeDetails,
        );
        expect(
          MapsUsageInterceptor.classifyRequest(
            request('https://maps.googleapis.com/maps/api/geocode/json'),
          ),
          MapsService.geocoding,
        );
      },
    );
  });
}
