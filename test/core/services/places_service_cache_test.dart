import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/services/address_formatter_service.dart';
import 'package:fraya_mobile/core/services/geocoding_service.dart';
import 'package:fraya_mobile/core/services/places_autocomplete_memory_cache.dart';
import 'package:fraya_mobile/core/services/places_cache_service.dart';
import 'package:fraya_mobile/core/services/places_service.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();
  });

  test('queries shorter than min length never call Google', () async {
    final adapter = _FakeGoogleAdapter();
    final service = _service(adapter);

    for (final query in ['a', 'an']) {
      expect(await service.getAutocompleteSuggestions(query), isEmpty);
    }

    expect(adapter.autocompleteCalls, 0);
  });

  test('query with min length calls Google when caches miss', () async {
    final adapter = _FakeGoogleAdapter(
      autocompleteBody: _autocompleteBody('place_1'),
    );
    final service = _service(adapter);

    final suggestions = await service.getAutocompleteSuggestions('ang');

    expect(adapter.autocompleteCalls, 1);
    expect(suggestions.single.placeId, 'place_1');
  });

  test('same query uses memory cache during the session', () async {
    final adapter = _FakeGoogleAdapter(
      autocompleteBody: _autocompleteBody('place_1'),
    );
    final service = _service(adapter);

    await service.getAutocompleteSuggestions('angre');
    final suggestions = await service.getAutocompleteSuggestions('  Angre  ');

    expect(adapter.autocompleteCalls, 1);
    expect(suggestions.single.placeId, 'place_1');
  });

  test('bypassCache skips memory autocomplete cache', () async {
    final adapter = _FakeGoogleAdapter(
      autocompleteBody: _autocompleteBody('place_1'),
    );
    final service = _service(adapter);

    await service.getAutocompleteSuggestions('angre');
    await service.getAutocompleteSuggestions('angre', bypassCache: true);

    expect(adapter.autocompleteCalls, 2);
  });

  test(
    'valid query placeIds rebuild autocomplete from details cache',
    () async {
      final firstAdapter = _FakeGoogleAdapter(
        autocompleteBody: _autocompleteBody('place_1'),
        detailsBody: _detailsBody('place_1', 'Neobureau'),
      );
      final firstService = _service(firstAdapter);

      await firstService.getAutocompleteSuggestions('angre');
      await firstService.getPlaceDetails('place_1');

      final secondAdapter = _FakeGoogleAdapter();
      final secondService = _service(secondAdapter);
      final suggestions = await secondService.getAutocompleteSuggestions(
        'angre',
      );

      expect(secondAdapter.autocompleteCalls, 0);
      expect(suggestions.single.placeId, 'place_1');
      expect(suggestions.single.localDetails, isNotNull);
      expect(suggestions.single.secondaryText, 'Angre 8eme tranche, Cocody');
    },
  );

  test(
    'persistent autocomplete rebuilt from details includes distance',
    () async {
      final firstAdapter = _FakeGoogleAdapter(
        autocompleteBody: _autocompleteBody('place_1'),
        detailsBody: _detailsBody('place_1', 'Neobureau'),
      );
      final firstService = _service(firstAdapter);

      await firstService.getAutocompleteSuggestions(
        'angre',
        originLat: 5.39,
        originLng: -4,
      );
      await firstService.getPlaceDetails('place_1');

      final secondAdapter = _FakeGoogleAdapter();
      final secondService = _service(secondAdapter);
      final suggestions = await secondService.getAutocompleteSuggestions(
        'angre',
        originLat: 5.39,
        originLng: -4,
      );

      expect(secondAdapter.autocompleteCalls, 0);
      expect(suggestions.single.distanceMeters, greaterThan(0));
    },
  );

  test('expired place details are fetched again after thirty days', () async {
    var now = DateTime(2026, 1);
    final cache = PlacesCacheService(now: () => now);
    await cache.saveDetails(
      const PlaceDetails(
        placeId: 'place_1',
        name: 'Ancien',
        address: 'Ancien, Cocody',
        latitude: 5.39,
        longitude: -3.99,
      ),
    );
    now = now.add(const Duration(days: 31));

    final adapter = _FakeGoogleAdapter(
      detailsBody: _detailsBody('place_1', 'Nouveau'),
    );
    final service = _service(adapter, cacheService: cache);

    final details = await service.getPlaceDetails('place_1');

    expect(adapter.detailsCalls, 1);
    expect(details?.name, 'Nouveau');
  });

  test('complete place details do not trigger reverse geocoding', () async {
    final adapter = _FakeGoogleAdapter(
      detailsBody: _detailsBody('place_1', 'Neobureau'),
    );
    final geocoding = _FakeGeocodingService(
      const AddressParts(streetOrQuarter: 'Autre rue', commune: 'Cocody'),
    );
    final service = _service(adapter, geocodingService: geocoding);

    await service.getPlaceDetails('place_1');

    expect(geocoding.calls, 0);
    expect(adapter.detailsFields, contains('address_components'));
  });

  test('incomplete details merge route with geocoded commune', () async {
    final adapter = _FakeGoogleAdapter(
      detailsBody: _incompleteDetailsBody(includeRoute: true),
    );
    final geocoding = _FakeGeocodingService(
      const AddressParts(streetOrQuarter: '', commune: 'Cocody'),
    );
    final service = _service(adapter, geocodingService: geocoding);

    final details = await service.getPlaceDetails('poor_place');

    expect(geocoding.calls, 1);
    expect(details?.localityLabel, 'Avenue Aka, Cocody');
    expect(details?.address, 'Avenue Aka, Cocody');
  });

  test(
    'failed enrichment keeps place selectable without technical text',
    () async {
      final adapter = _FakeGoogleAdapter(detailsBody: _incompleteDetailsBody());
      final geocoding = _FakeGeocodingService(null);
      final service = _service(adapter, geocodingService: geocoding);

      final details = await service.getPlaceDetails('poor_place');

      expect(geocoding.calls, 1);
      expect(details?.localityLabel, isNull);
      expect(details?.address, 'Lieu recherché');
      expect(details?.address, isNot(contains('8XJV')));
    },
  );
}

PlacesService _service(
  _FakeGoogleAdapter adapter, {
  PlacesCacheService? cacheService,
  GeocodingService? geocodingService,
}) {
  final dio = Dio()..httpClientAdapter = adapter;
  return PlacesService(
    googleDio: dio,
    cacheService: cacheService ?? PlacesCacheService(),
    autocompleteMemoryCache: PlacesAutocompleteMemoryCache(),
    geocodingService: geocodingService,
  );
}

Map<String, dynamic> _autocompleteBody(String placeId) => {
  'status': 'OK',
  'predictions': [
    {
      'place_id': placeId,
      'description': 'Angre 8eme tranche, Cocody, Abidjan',
      'structured_formatting': {
        'main_text': 'Neobureau',
        'secondary_text': 'Cocody, Abidjan',
      },
    },
  ],
};

Map<String, dynamic> _detailsBody(String placeId, String name) => {
  'status': 'OK',
  'result': {
    'place_id': placeId,
    'name': name,
    'formatted_address': 'Angre 8eme tranche, Cocody, Abidjan',
    'geometry': {
      'location': {'lat': 5.39, 'lng': -3.99},
    },
    'address_components': [
      {
        'long_name': 'Angre 8eme tranche',
        'short_name': 'Angre 8eme tranche',
        'types': ['neighborhood', 'political'],
      },
      {
        'long_name': 'Cocody',
        'short_name': 'Cocody',
        'types': ['political', 'sublocality', 'sublocality_level_1'],
      },
      {
        'long_name': 'Abidjan',
        'short_name': 'Abidjan',
        'types': ['locality', 'political'],
      },
    ],
  },
};

Map<String, dynamic> _incompleteDetailsBody({bool includeRoute = false}) => {
  'status': 'OK',
  'result': {
    'place_id': 'poor_place',
    'name': 'Lieu recherché',
    'formatted_address': '8XJV+77P, Abidjan, Cote d\'Ivoire',
    'geometry': {
      'location': {'lat': 5.35, 'lng': -4.01},
    },
    'address_components': [
      {
        'long_name': '8XJV+77P',
        'short_name': '8XJV+77P',
        'types': ['plus_code'],
      },
      if (includeRoute)
        {
          'long_name': 'Avenue Aka',
          'short_name': 'Av. Aka',
          'types': ['route'],
        },
      {
        'long_name': 'Abidjan',
        'short_name': 'Abidjan',
        'types': ['locality', 'political'],
      },
    ],
  },
};

class _FakeGoogleAdapter implements HttpClientAdapter {
  _FakeGoogleAdapter({this.autocompleteBody, this.detailsBody});

  final Map<String, dynamic>? autocompleteBody;
  final Map<String, dynamic>? detailsBody;
  int autocompleteCalls = 0;
  int detailsCalls = 0;
  String? detailsFields;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/autocomplete/')) {
      autocompleteCalls++;
      return _jsonResponse(autocompleteBody ?? {'status': 'ZERO_RESULTS'});
    }
    if (options.path.contains('/details/')) {
      detailsCalls++;
      detailsFields = options.queryParameters['fields']?.toString();
      return _jsonResponse(detailsBody ?? {'status': 'NOT_FOUND'});
    }
    return _jsonResponse({'status': 'NOT_FOUND'}, statusCode: 404);
  }

  @override
  void close({bool force = false}) {}

  ResponseBody _jsonResponse(
    Map<String, dynamic> body, {
    int statusCode = 200,
  }) {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );
  }
}

class _FakeGeocodingService extends GeocodingService {
  _FakeGeocodingService(this.result);

  final AddressParts? result;
  int calls = 0;

  @override
  Future<AddressParts?> resolveAddress(double lat, double lng) async {
    calls++;
    return result;
  }
}
