import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/data/sources/remote/driver_ride_remote_data_source.dart';

class RecordingHttpClientAdapter implements HttpClientAdapter {
  RecordingHttpClientAdapter(this._handler);

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
  group('DriverRideRemoteDataSource', () {
    test('acceptRide sends rideId, driverId and vehicleId', () async {
      RequestOptions? capturedOptions;
      final dataSource = DriverRideRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            await requestStream?.drain<void>();
            capturedOptions = options;
            return _jsonResponse({'success': true}, 200);
          }),
      );

      await dataSource.acceptRide('34', driverId: 18, vehicleId: 3);

      expect(capturedOptions?.path, '/rides/maps/34/accept');
      expect(capturedOptions?.data, {
        'rideId': 34,
        'driverId': 18,
        'vehicleId': 3,
      });
    });

    test('markArrived sends driver coordinates', () async {
      RequestOptions? capturedOptions;
      final dataSource = DriverRideRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            await requestStream?.drain<void>();
            capturedOptions = options;
            return _jsonResponse({'success': true}, 200);
          }),
      );

      await dataSource.markArrived('34', driverLat: 5.36, driverLng: -4.02);

      expect(capturedOptions?.path, '/rides/maps/34/arrived');
      expect(capturedOptions?.data, {
        'rideId': 34,
        'driverLat': '5.36',
        'driverLng': '-4.02',
      });
    });

    test('completeRide sends final metrics payload', () async {
      RequestOptions? capturedOptions;
      final dataSource = DriverRideRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            await requestStream?.drain<void>();
            capturedOptions = options;
            return _jsonResponse({'success': true}, 200);
          }),
      );

      await dataSource.completeRide(
        '34',
        finalDistanceKm: 12.4,
        finalDurationMin: 27,
        finalPrice: 5650,
        additionnalFreeSeconds: 120,
      );

      expect(capturedOptions?.path, '/rides/maps/34/complete');
      expect(capturedOptions?.data, {
        'rideId': 34,
        'finalDistanceKm': '12.4',
        'finalDurationMin': '27',
        'finalPrice': '5650',
        'additionnalFree': 120,
      });
      expect(capturedOptions?.data, isNot(contains('lateDuration')));
      expect(capturedOptions?.data, isNot(contains('additionnalFee')));
    });

    test('sendDriverLocation posts active ride position payload', () async {
      RequestOptions? capturedOptions;
      final dataSource = DriverRideRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            await requestStream?.drain<void>();
            capturedOptions = options;
            return _jsonResponse({'success': true}, 200);
          }),
      );

      await dataSource.sendDriverLocation(
        rideId: '34',
        driverId: 18,
        lat: 5.359517,
        lng: -4.0025363,
      );

      final data = Map<String, dynamic>.from(
        capturedOptions?.data as Map<dynamic, dynamic>,
      );
      final timestamp = data.remove('timestamp') as String?;

      expect(capturedOptions?.path, '/rides/maps/34/positions');
      expect(data, {
        'driverId': 18,
        'latitude': 5.359517,
        'longitude': -4.0025363,
      });
      expect(DateTime.tryParse(timestamp ?? ''), isNotNull);
    });

    test(
      'sendDriverAvailabilityLocation posts nearby driver payload',
      () async {
        RequestOptions? capturedOptions;
        final dataSource = DriverRideRemoteDataSource(
          dio: Dio()
            ..httpClientAdapter = RecordingHttpClientAdapter((
              options,
              requestStream,
              cancelFuture,
            ) async {
              await requestStream?.drain<void>();
              capturedOptions = options;
              return _jsonResponse({'success': true}, 200);
            }),
        );

        await dataSource.sendDriverAvailabilityLocation(
          lat: 5.359517,
          lng: -4.0025363,
        );

        final data = Map<String, dynamic>.from(
          capturedOptions?.data as Map<dynamic, dynamic>,
        );
        final timestamp = data.remove('timestamp') as String?;

        expect(capturedOptions?.path, '/rides/maps/drivers/location');
        expect(data, {'latitude': 5.359517, 'longitude': -4.0025363});
        expect(DateTime.tryParse(timestamp ?? ''), isNotNull);
      },
    );

    test(
      'acceptRide maps 409 already taken to assigned-driver message',
      () async {
        final dataSource = DriverRideRemoteDataSource(
          dio: Dio()
            ..httpClientAdapter = RecordingHttpClientAdapter((
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
                  data: {'message': 'already taken'},
                ),
              );
            }),
        );

        expect(
          () => dataSource.acceptRide('34', driverId: 18, vehicleId: 3),
          throwsA(
            isA<ServerException>().having(
              (error) => error.message,
              'message',
              'Cette course a déjà été attribuée à un autre chauffeur.',
            ),
          ),
        );
      },
    );

    test(
      'acceptRide maps cancelled ride conflict to cancelled message',
      () async {
        final dataSource = DriverRideRemoteDataSource(
          dio: Dio()
            ..httpClientAdapter = RecordingHttpClientAdapter((
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
                  data: {'message': 'Ride cancelled by passenger'},
                ),
              );
            }),
        );

        expect(
          () => dataSource.acceptRide('34', driverId: 18, vehicleId: 3),
          throwsA(
            isA<ServerException>().having(
              (error) => error.message,
              'message',
              'Cette course a été annulée entre-temps.',
            ),
          ),
        );
      },
    );

    test('throws on unexpected action response status', () async {
      final dataSource = DriverRideRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            await requestStream?.drain<void>();
            return _jsonResponse({'success': true}, 202);
          }),
      );

      expect(() => dataSource.startRide('34'), throwsA(isA<ServerException>()));
    });

    test(
      'getAllRides supports wrapped, direct and unexpected payloads',
      () async {
        final dio = Dio();
        var callIndex = 0;
        dio.httpClientAdapter = RecordingHttpClientAdapter((
          options,
          requestStream,
          cancelFuture,
        ) async {
          await requestStream?.drain<void>();
          callIndex++;
          return switch (callIndex) {
            1 => _jsonResponse({
              'data': {
                'rides': [
                  {'id': 1},
                ],
              },
            }, 200),
            2 => _jsonResponse([
              {'id': 2},
            ], 200),
            _ => _jsonResponse('unexpected', 200),
          };
        });
        final dataSource = DriverRideRemoteDataSource(dio: dio);

        final wrapped = await dataSource.getAllRides();
        final direct = await dataSource.getAllRides();
        final unexpected = await dataSource.getAllRides();

        expect(wrapped, [
          {'id': 1},
        ]);
        expect(direct, [
          {'id': 2},
        ]);
        expect(unexpected, isEmpty);
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
