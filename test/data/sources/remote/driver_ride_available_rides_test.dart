import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/remote/driver_ride_remote_data_source.dart';

void main() {
  test(
    'temporarily loads available rides from the all rides endpoint',
    () async {
      RequestOptions? capturedOptions;
      final dio = Dio()
        ..httpClientAdapter = _RecordingHttpClientAdapter((options) {
          capturedOptions = options;
          return _jsonResponse({'data': <dynamic>[]}, 200);
        });
      final dataSource = DriverRideRemoteDataSource(dio: dio);

      await dataSource.getAvailableRides(lat: 5.3, lng: -4, radiusKm: 10);

      expect(capturedOptions?.path, '/rides/maps');
    },
  );
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

class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
