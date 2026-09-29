import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/remote/driver_status_remote_data_source.dart';

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
  group('DriverStatusRemoteDataSource', () {
    test('updateStatus sends sid user online route and payload', () async {
      RequestOptions? capturedOptions;
      final dataSource = DriverStatusRemoteDataSource(
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

      await dataSource.updateStatus(isOnline: true);

      expect(capturedOptions?.method, 'PUT');
      expect(capturedOptions?.path, '/sid-users/me/online');
      expect(capturedOptions?.data, {'isOnline': true});
    });

    test('updateStatus accepts offline payload and 204 response', () async {
      RequestOptions? capturedOptions;
      final dataSource = DriverStatusRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            await requestStream?.drain<void>();
            capturedOptions = options;
            return _jsonResponse({}, 204);
          }),
      );

      await dataSource.updateStatus(isOnline: false);

      expect(capturedOptions?.path, '/sid-users/me/online');
      expect(capturedOptions?.data, {'isOnline': false});
    });

    test('sendHeartbeat posts me heartbeat without a body', () async {
      RequestOptions? capturedOptions;
      final dataSource = DriverStatusRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            await requestStream?.drain<void>();
            capturedOptions = options;
            return _jsonResponse({'success': true}, 201);
          }),
      );

      await dataSource.sendHeartbeat();

      expect(capturedOptions?.method, 'POST');
      expect(capturedOptions?.path, '/sid-users/me/heartbeat');
      expect(capturedOptions?.data, isNull);
    });
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
