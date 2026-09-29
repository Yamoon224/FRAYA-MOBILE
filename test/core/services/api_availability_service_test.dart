import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/api_availability_guard.dart';
import 'package:fraya_mobile/core/services/api_availability_service.dart';

class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('check treats an HTTP 405 response as reachable', () async {
    final dio = Dio()
      ..httpClientAdapter = _RecordingHttpClientAdapter((options) async {
        expect(options.method, 'HEAD');
        return ResponseBody.fromString('', 405);
      });
    final service = ApiAvailabilityService(
      dio: dio,
      baseUrl: 'https://api.example.test/root',
    );

    final status = await service.check();

    expect(status, ApiAvailabilityState.reachable);
  });

  test('check falls back to GET before declaring unreachable', () async {
    final methods = <String>[];
    final dio = Dio()
      ..httpClientAdapter = _RecordingHttpClientAdapter((options) async {
        methods.add(options.method);
        if (options.method == 'HEAD') {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'head blocked',
          );
        }
        return ResponseBody.fromString('', 404);
      });
    final service = ApiAvailabilityService(
      dio: dio,
      baseUrl: 'https://api.example.test/root',
    );

    final status = await service.check();

    expect(status, ApiAvailabilityState.reachable);
    expect(methods, ['HEAD', 'GET']);
  });
}
