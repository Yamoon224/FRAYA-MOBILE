import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/services/directions_service.dart';
import 'package:fraya_mobile/core/services/geocoding_service.dart';
import 'package:fraya_mobile/core/services/places_cache_service.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dio factice qui compte les appels sortants vers Google.
class _CountingDio implements Dio {
  _CountingDio({required this.getPayload});

  final Map<String, dynamic> Function() getPayload;
  int gets = 0;
  int posts = 0;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onReceiveProgress,
  }) async {
    gets++;
    return Response<T>(
      data: getPayload() as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    posts++;
    return Response<T>(
      data: <String, dynamic>{} as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _geocodeOk(String street) => {
  'status': 'OK',
  'results': [
    {
      'types': ['route'],
      'formatted_address': '$street, Cocody, Abidjan',
      'address_components': [
        {
          'long_name': street,
          'types': ['route'],
        },
        {
          'long_name': 'Cocody',
          'types': ['sublocality_level_1'],
        },
        {
          'long_name': 'Abidjan',
          'types': ['locality'],
        },
      ],
      'place_id': 'pid-$street',
    },
  ],
};

Map<String, dynamic> _directionsOk() => {
  'status': 'OK',
  'routes': [
    {
      'legs': [
        {
          'distance': {'value': 1000, 'text': '1 km'},
          'duration': {'value': 120, 'text': '2 min'},
          'steps': <dynamic>[],
        },
      ],
      'overview_polyline': {'points': '_p~iF~ps|U_ulLnnqC_mqNvxq`@'},
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'GOOGLE_PLACES_API_KEY=test-key');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();
  });

  group('Géocodage inverse mis en cache', () {
    test(
      'un même endroit (à ~11 m) ne déclenche qu\'un appel Google',
      () async {
        final dio = _CountingDio(getPayload: () => _geocodeOk('Rue Konan'));
        final service = GeocodingService(dio: dio);

        final first = await service.reverseGeocode(5.320011, -4.020022);
        final second = await service.reverseGeocode(5.320014, -4.020024);

        expect(dio.gets, 1);
        expect(second, first);
        expect(first['formatted'], isNotEmpty);
        expect(first['placeId'], 'pid-Rue Konan');
      },
    );

    test('un autre endroit déclenche un nouvel appel', () async {
      final dio = _CountingDio(getPayload: () => _geocodeOk('Rue Konan'));
      final service = GeocodingService(dio: dio);

      await service.reverseGeocode(5.32, -4.02);
      await service.reverseGeocode(5.33, -4.03);

      expect(dio.gets, 2);
    });

    test(
      'survit au redémarrage (cache disque) puis expire après 7 jours',
      () async {
        var now = DateTime(2026, 1);
        final dio = _CountingDio(getPayload: () => _geocodeOk('Rue Konan'));
        await GeocodingService(
          dio: dio,
          now: () => now,
        ).reverseGeocode(5.3, -4.0);

        // Nouvelle instance = redémarrage : la mémoire est vide, le disque répond.
        final restarted = GeocodingService(dio: dio, now: () => now);
        await restarted.reverseGeocode(5.3, -4.0);
        expect(dio.gets, 1);

        now = now.add(const Duration(days: 8));
        await GeocodingService(
          dio: dio,
          now: () => now,
        ).reverseGeocode(5.3, -4.0);
        expect(dio.gets, 2);
      },
    );

    test('un échec n\'est pas mis en cache et peut être retenté', () async {
      var failing = true;
      final dio = _CountingDio(
        getPayload: () => failing
            ? {'status': 'OVER_QUERY_LIMIT', 'results': <dynamic>[]}
            : _geocodeOk('Rue Konan'),
      );
      final service = GeocodingService(dio: dio);

      final failed = await service.reverseGeocode(5.3, -4.0);
      expect(failed['formatted'], isEmpty);

      failing = false;
      final retried = await service.reverseGeocode(5.3, -4.0);
      expect(retried['formatted'], isNotEmpty);
      expect(dio.gets, 2);
    });
  });

  group(
    'Itinéraire chauffeur : Routes API seulement si le trafic est affiché',
    () {
      const origin = LatLng(5.30, -4.00);
      const destination = LatLng(5.31, -4.01);

      test(
        'désactivé : un seul appel (Directions), aucun appel Routes',
        () async {
          final dio = _CountingDio(getPayload: _directionsOk);
          final service = DirectionsService(
            googleDio: dio,
            includeTrafficSegments: false,
          );

          final result = await service.getDirections(
            origin: origin,
            destination: destination,
          );

          expect(dio.gets, 1);
          expect(dio.posts, 0);
          expect(result, isNotNull);
          expect(result!.mainRoute.distanceValue, 1000);
          expect(result.mainRoute.hasTrafficData, isFalse);
        },
      );

      test(
        'activé par défaut : comportement passager inchangé (2 appels)',
        () async {
          final dio = _CountingDio(getPayload: _directionsOk);
          final service = DirectionsService(googleDio: dio);

          await service.getDirections(origin: origin, destination: destination);

          expect(dio.gets, 1);
          expect(dio.posts, 1);
        },
      );
    },
  );

  group('Lieux proches conservés sur disque', () {
    PlaceDetails place(String id) => PlaceDetails(
      placeId: id,
      name: 'Mall $id',
      address: 'Cocody, Abidjan',
      latitude: 5.3,
      longitude: -4.0,
      types: const ['shopping_mall'],
    );

    test('relu après redémarrage, types conservés pour le tri', () async {
      var now = DateTime(2026, 1);
      await PlacesCacheService(
        now: () => now,
      ).saveNearby('5.30,-4.00|10000|poi|fr', [place('a'), place('b')]);

      now = now.add(const Duration(hours: 11));
      final read = PlacesCacheService(
        now: () => now,
      ).readNearby('5.30,-4.00|10000|poi|fr', const Duration(hours: 12));

      expect(read, isNotNull);
      expect(read!.map((p) => p.placeId), ['a', 'b']);
      expect(read.first.types, ['shopping_mall']);
    });

    test('expire après 12 h', () async {
      var now = DateTime(2026, 1);
      final cache = PlacesCacheService(now: () => now);
      await cache.saveNearby('k', [place('a')]);

      now = now.add(const Duration(hours: 13));

      expect(cache.readNearby('k', const Duration(hours: 12)), isNull);
    });
  });
}
