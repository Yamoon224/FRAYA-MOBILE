import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/remote/device_registration_remote_data_source.dart';
import 'package:fraya_mobile/domain/models/device_registration.dart';

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
  group('DeviceRegistrationRemoteDataSource', () {
    test(
      'register does not send a request while endpoint is disabled',
      () async {
        var requestCount = 0;
        final dataSource = DeviceRegistrationRemoteDataSource(
          dio: Dio()
            ..httpClientAdapter = RecordingHttpClientAdapter((
              options,
              requestStream,
              cancelFuture,
            ) async {
              requestCount++;
              return _jsonResponse({'success': true}, 201);
            }),
        );

        await dataSource.register(_registration);

        expect(requestCount, 0);
      },
    );

    test(
      'deactivate does not send a request while endpoint is disabled',
      () async {
        var requestCount = 0;
        final dataSource = DeviceRegistrationRemoteDataSource(
          dio: Dio()
            ..httpClientAdapter = RecordingHttpClientAdapter((
              options,
              requestStream,
              cancelFuture,
            ) async {
              requestCount++;
              return _jsonResponse({}, 204);
            }),
        );

        await dataSource.deactivate(_registration);

        expect(requestCount, 0);
      },
    );
  });
}

const _registration = DeviceRegistration(
  userId: '24',
  role: 'DRIVER',
  oneSignalSubscriptionId: 'sub-abc',
  platform: 'android',
);

ResponseBody _jsonResponse(Object body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
