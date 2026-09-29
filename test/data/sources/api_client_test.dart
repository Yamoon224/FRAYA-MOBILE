import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/services/api_availability_guard.dart';
import 'package:fraya_mobile/data/sources/api_client.dart';

class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    AppConfig.instance.init(flavor: AppFlavor.passenger);
    ApiAvailabilityGuard.instance.reset();
    ApiClient.instance.init();
  });

  tearDown(ApiAvailabilityGuard.instance.reset);

  test('blocks mutating requests when API is confirmed unreachable', () async {
    var calls = 0;
    ApiClient.instance.dio.httpClientAdapter = _RecordingHttpClientAdapter((
      options,
    ) async {
      calls++;
      return ResponseBody.fromString('', 200);
    });
    ApiAvailabilityGuard.instance.setState(ApiAvailabilityState.unreachable);

    await expectLater(
      ApiClient.instance.dio.post('/rides/maps/request'),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'error',
          isA<NetworkException>(),
        ),
      ),
    );

    expect(calls, 0);
  });

  test('allows GET requests while API mutations are blocked', () async {
    var calls = 0;
    ApiClient.instance.dio.httpClientAdapter = _RecordingHttpClientAdapter((
      options,
    ) async {
      calls++;
      expect(options.method, 'GET');
      return ResponseBody.fromString('', 200);
    });
    ApiAvailabilityGuard.instance.setState(ApiAvailabilityState.unreachable);

    final response = await ApiClient.instance.dio.get('/rides/maps');

    expect(response.statusCode, 200);
    expect(calls, 1);
  });

  test('allows mutating requests after API recovery', () async {
    var calls = 0;
    ApiClient.instance.dio.httpClientAdapter = _RecordingHttpClientAdapter((
      options,
    ) async {
      calls++;
      expect(options.method, 'POST');
      return ResponseBody.fromString('', 200);
    });
    ApiAvailabilityGuard.instance.setState(ApiAvailabilityState.reachable);

    final response = await ApiClient.instance.dio.post('/rides/maps/request');

    expect(response.statusCode, 200);
    expect(calls, 1);
  });
}
