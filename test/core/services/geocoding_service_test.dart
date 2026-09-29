import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/geocoding_service.dart';

class _FakeDio implements Dio {
  _FakeDio(this._payload);

  final Map<String, dynamic> _payload;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onReceiveProgress,
  }) async {
    return Response<T>(
      data: _payload as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'GOOGLE_PLACES_API_KEY=test-key');
  });

  test(
    'promotes sublocality commune over Abidjan for reverse geocoding',
    () async {
      final dio = _FakeDio(<String, dynamic>{
        'status': 'OK',
        'results': <Map<String, dynamic>>[
          <String, dynamic>{
            'formatted_address': "Rue Konan, Cocody, Abidjan, Cote d'Ivoire",
            'address_components': <Map<String, dynamic>>[
              <String, dynamic>{
                'long_name': 'Abidjan',
                'types': <String>['locality'],
              },
              <String, dynamic>{
                'long_name': 'Cocody',
                'types': <String>['sublocality_level_1'],
              },
              <String, dynamic>{
                'long_name': 'Rue Konan',
                'types': <String>['route'],
              },
              <String, dynamic>{
                'long_name': '36',
                'types': <String>['street_number'],
              },
            ],
          },
        ],
      });

      final service = GeocodingService(dio: dio);
      final result = await service.reverseGeocode(5.3, -3.9);

      expect(result['commune'], 'Cocody');
      expect(result['formatted'], '36 Rue Konan, Cocody');
    },
  );

  test('selects a precise route instead of a plus code result', () async {
    final dio = _FakeDio(<String, dynamic>{
      'status': 'OK',
      'results': <Map<String, dynamic>>[
        <String, dynamic>{
          'types': <String>['plus_code'],
          'formatted_address': '8XJV+77P, Abidjan',
          'address_components': <Map<String, dynamic>>[
            <String, dynamic>{
              'long_name': '8XJV+77P',
              'types': <String>['plus_code'],
            },
            <String, dynamic>{
              'long_name': 'Abidjan',
              'types': <String>['locality'],
            },
          ],
        },
        <String, dynamic>{
          'types': <String>['route'],
          'formatted_address': 'Avenue Aka, Cocody, Abidjan',
          'address_components': <Map<String, dynamic>>[
            <String, dynamic>{
              'long_name': 'Avenue Aka',
              'types': <String>['route'],
            },
            <String, dynamic>{
              'long_name': 'Cocody',
              'types': <String>['sublocality_level_1'],
            },
            <String, dynamic>{
              'long_name': 'Abidjan',
              'types': <String>['locality'],
            },
          ],
        },
      ],
    });

    final result = await GeocodingService(dio: dio).reverseGeocode(5.3, -3.9);

    expect(result['formatted'], 'Avenue Aka, Cocody');
  });
}
