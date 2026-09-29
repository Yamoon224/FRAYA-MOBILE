import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/data/sources/remote/booking_remote_data_source.dart';

class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  )
  _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('BookingRemoteDataSource.calculatePrices', () {
    test(
      'sends neutral estimate payload without range or coordinates',
      () async {
        late String path;
        late Map<String, dynamic> body;
        final dataSource = BookingRemoteDataSource(
          dio: Dio()
            ..httpClientAdapter = _RecordingHttpClientAdapter((
              options,
              requestStream,
              cancelFuture,
            ) async {
              path = options.path;
              body = await _decodeRequestBody(requestStream);
              return _jsonResponse({
                'success': true,
                'data': {
                  'data': {'prices': []},
                },
              }, 200);
            }),
        );

        await dataSource.calculatePrices(
          const CalculateRidePricesParams(
            latDeparture: 5.31,
            longDeparture: -4.01,
            arrivalPlaceId: 'google_destination_123',
            arrivalLat: 5.25,
            arrivalLong: -3.93,
          ),
        );

        expect(path, '/rides/maps/estimate');
        expect(body, {
          'currentLat': 5.31,
          'currentLng': -4.01,
          'destinationPlaceId': 'google_destination_123',
          'stops': <dynamic>[],
          'promoCode': '',
          'waitingSeconds': 0,
        });
        expect(body.containsKey('range'), isFalse);
        expect(body.containsKey('arrivalLat'), isFalse);
        expect(body.containsKey('arrivalLong'), isFalse);
      },
    );

    test('serializes stops, promo code, and waiting seconds', () async {
      late Map<String, dynamic> body;
      final dataSource = BookingRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = _RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            body = await _decodeRequestBody(requestStream);
            return _jsonResponse({
              'success': true,
              'data': {
                'data': {'prices': []},
              },
            }, 200);
          }),
      );

      await dataSource.calculatePrices(
        const CalculateRidePricesParams(
          latDeparture: 5.31,
          longDeparture: -4.01,
          arrivalPlaceId: 'google_destination_123',
          arrivalLat: 5.25,
          arrivalLong: -3.93,
          stops: [
            RideEstimateStop(position: 1, placeId: 'google_stop_123'),
            RideEstimateStop(position: 2, placeId: 'google_stop_456'),
          ],
          promoCode: 'FRAYA25',
          waitingSeconds: 120,
        ),
      );

      expect(body['stops'], [
        {'position': 1, 'placeId': 'google_stop_123'},
        {'position': 2, 'placeId': 'google_stop_456'},
      ]);
      expect(body['promoCode'], 'FRAYA25');
      expect(body['waitingSeconds'], 120);
      expect(body.containsKey('range'), isFalse);
    });
  });

  group('BookingRemoteDataSource.rateRide', () {
    test('accepts 202 and 204 as submitted outcome', () async {
      final dio = Dio();
      var callIndex = 0;
      dio.httpClientAdapter = _RecordingHttpClientAdapter((
        options,
        requestStream,
        cancelFuture,
      ) async {
        await requestStream?.drain<void>();
        callIndex++;
        if (callIndex == 1) {
          return _jsonResponse({'success': true}, 202);
        }
        return _jsonResponse('', 204);
      });
      final dataSource = BookingRemoteDataSource(dio: dio);

      final firstResult = await dataSource.rateRide(rideId: '90', rating: 5);
      final secondResult = await dataSource.rateRide(rideId: '91', rating: 4);

      expect(firstResult, RateRideOutcome.submitted);
      expect(secondResult, RateRideOutcome.submitted);
    });

    test(
      'maps duplicate rating backend error to alreadySubmitted outcome',
      () async {
        final dataSource = BookingRemoteDataSource(
          dio: Dio()
            ..httpClientAdapter = _RecordingHttpClientAdapter((
              options,
              requestStream,
              cancelFuture,
            ) async {
              await requestStream?.drain<void>();
              throw DioException.badResponse(
                statusCode: 409,
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 409,
                  data: {'message': 'Vous avez deja soumis un commentaire'},
                ),
              );
            }),
        );

        final result = await dataSource.rateRide(
          rideId: '100',
          rating: 5,
          comment: 'Top',
        );

        expect(result, RateRideOutcome.alreadySubmitted);
      },
    );

    test('maps 409 database error to alreadySubmitted outcome', () async {
      final dataSource = BookingRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = _RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            await requestStream?.drain<void>();
            throw DioException.badResponse(
              statusCode: 409,
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 409,
                data: {'message': 'database error'},
              ),
            );
          }),
      );

      final result = await dataSource.rateRide(
        rideId: '101',
        rating: 5,
        comment: 'Top',
      );

      expect(result, RateRideOutcome.alreadySubmitted);
    });

    test('throws for unrelated 409 backend error', () async {
      final dataSource = BookingRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = _RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            await requestStream?.drain<void>();
            throw DioException.badResponse(
              statusCode: 409,
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 409,
                data: {'message': 'quota exceeded'},
              ),
            );
          }),
      );

      expect(
        () => dataSource.rateRide(rideId: '199', rating: 5),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws for non-duplicate backend error', () async {
      final dataSource = BookingRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = _RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            await requestStream?.drain<void>();
            throw DioException.badResponse(
              statusCode: 500,
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 500,
                data: {'message': 'Internal error'},
              ),
            );
          }),
      );

      expect(
        () => dataSource.rateRide(rideId: '200', rating: 5),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('BookingRemoteDataSource.triggerSos', () {
    test('sends swagger-compatible SOS payload', () async {
      late String path;
      late Map<String, dynamic> body;
      final dataSource = BookingRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = _RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            path = options.path;
            body = await _decodeRequestBody(requestStream);
            return _jsonResponse({'success': true}, 201);
          }),
      );

      final result = await dataSource.triggerSos(
        rideId: '77',
        userId: 12,
        lat: 5.34,
        lng: -4.02,
        notes: 'GPS indisponible - Accident',
      );

      expect(result, isTrue);
      expect(path, '/alerts/create');
      expect(body, {
        'courseId': 77,
        'passagerId': 12,
        'userId': 12,
        'lat': 5.34,
        'lng': -4.02,
        'sendPolice': false,
        'sendContacts': false,
        'notes': 'GPS indisponible - Accident',
      });
      expect(body.containsKey('type'), isFalse);
      expect(body.containsKey('source'), isFalse);
      expect(body.containsKey('reason'), isFalse);
      expect(body.containsKey('latitude'), isFalse);
      expect(body.containsKey('longitude'), isFalse);
    });

    test('maps not-found SOS errors to a readable French message', () async {
      final dataSource = BookingRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = _RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            await requestStream?.drain<void>();
            throw DioException.badResponse(
              statusCode: 404,
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 404,
                data: {'message': 'Course, passenger or chauffeur not found'},
              ),
            );
          }),
      );

      expect(
        () => dataSource.triggerSos(
          rideId: '77',
          userId: 12,
          lat: 5.34,
          lng: -4.02,
        ),
        throwsA(
          isA<ServerException>().having(
            (error) => error.message,
            'message',
            'Course introuvable.',
          ),
        ),
      );
    });
  });

  group('BookingRemoteDataSource.createRideShareLink', () {
    test('posts share request with expiresIn and parses the tracking url', () async {
      late String path;
      late Map<String, dynamic> body;
      final dataSource = BookingRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = _RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            path = options.path;
            body = await _decodeRequestBody(requestStream);
            return _jsonResponse({
              'success': true,
              'data': {
                'share': {
                  'token': 'fraya-token',
                  'url': 'https://manager.frayataxi.ci/ride/tracking/fraya-token',
                  'expiresAt': '2026-06-24T09:36:46.186Z',
                  'isValid': true,
                },
              },
            }, 200);
          }),
      );

      final result = await dataSource.createRideShareLink(
        rideId: '40',
        expiresIn: 60,
      );

      expect(path, '/rides/maps/40/share');
      expect(body, {'expiresIn': 60});
      expect(result.token, 'fraya-token');
      expect(
        result.url,
        'https://manager.frayataxi.ci/ride/tracking/fraya-token',
      );
      expect(result.isValid, isTrue);
    });

    test('throws when share url is missing from the payload', () async {
      final dataSource = BookingRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = _RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            await requestStream?.drain<void>();
            return _jsonResponse({
              'success': true,
              'data': {
                'share': {'token': 'fraya-token', 'isValid': true},
              },
            }, 200);
          }),
      );

      expect(
        () => dataSource.createRideShareLink(rideId: '40'),
        throwsA(
          isA<ServerException>().having(
            (error) => error.message,
            'message',
            'Impossible de generer le lien de suivi.',
          ),
        ),
      );
    });
  });

  group('BookingRemoteDataSource.createSupportTicket', () {
    test(
      'posts support ticket with mapped type, priority and enriched description',
      () async {
        late String path;
        late Map<String, dynamic> body;
        final dataSource = BookingRemoteDataSource(
          dio: Dio()
            ..httpClientAdapter = _RecordingHttpClientAdapter((
              options,
              requestStream,
              cancelFuture,
            ) async {
              path = options.path;
              body = await _decodeRequestBody(requestStream);
              return _jsonResponse({'success': true}, 201);
            }),
        );

        final result = await dataSource.createSupportTicket(
          rideId: '55',
          userId: 9,
          category: 'Chauffeur en retard',
          description: '10 min de retard',
        );

        expect(result, isTrue);
        expect(path, '/support/create');
        expect(body['userId'], 9);
        expect(body['courseId'], 55);
        expect(body['type'], 'DELAY');
        expect(body['priorite'], 'LOW');
        expect(
          body['description'],
          'Cat\u00e9gorie signal\u00e9e: Chauffeur en retard. Details: 10 min de retard',
        );
      },
    );

    test(
      'retries once with PRICE when backend rejects the support type field',
      () async {
        final capturedBodies = <Map<String, dynamic>>[];
        final dataSource = BookingRemoteDataSource(
          dio: Dio()
            ..httpClientAdapter = _RecordingHttpClientAdapter((
              options,
              requestStream,
              cancelFuture,
            ) async {
              capturedBodies.add(await _decodeRequestBody(requestStream));
              if (capturedBodies.length == 1) {
                throw DioException.badResponse(
                  statusCode: 400,
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 400,
                    data: {
                      'message': 'Validation failed',
                      'errors': {
                        'type': ['invalid enum value'],
                      },
                    },
                  ),
                );
              }
              return _jsonResponse({'success': true}, 201);
            }),
        );

        final result = await dataSource.createSupportTicket(
          rideId: '91',
          userId: 7,
          category: 'Probl\u00e8me de s\u00e9curit\u00e9',
          description: null,
        );

        expect(result, isTrue);
        expect(capturedBodies, hasLength(2));
        expect(capturedBodies.first['type'], 'SAFETY');
        expect(capturedBodies.first['priorite'], 'HIGH');
        expect(capturedBodies.last['type'], 'PRICE');
        expect(capturedBodies.last['priorite'], 'HIGH');
        expect(
          capturedBodies.last['description'],
          'Cat\u00e9gorie signal\u00e9e: Probl\u00e8me de s\u00e9curit\u00e9',
        );
      },
    );
  });
}

ResponseBody _jsonResponse(Object body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Future<Map<String, dynamic>> _decodeRequestBody(
  Stream<Uint8List>? requestStream,
) async {
  if (requestStream == null) return const {};

  final bytes = BytesBuilder(copy: false);
  await for (final chunk in requestStream) {
    bytes.add(chunk);
  }
  final content = utf8.decode(bytes.takeBytes());
  return Map<String, dynamic>.from(jsonDecode(content) as Map);
}
