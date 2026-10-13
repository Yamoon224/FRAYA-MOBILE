import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/services/api_availability_guard.dart';
import 'package:fraya_mobile/core/services/auth_session_notifier.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
import 'package:fraya_mobile/data/sources/api_client.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';

/// Simule le backend : access token d'1 h expiré => 401, refresh rotatif.
class _FakeBackend implements HttpClientAdapter {
  _FakeBackend({
    this.refreshHandler,
    this.alwaysUnauthorized = false,
  });

  static const validAccessToken = 'access-new';
  final Future<ResponseBody> Function(RequestOptions options)? refreshHandler;
  final bool alwaysUnauthorized;

  final refreshBodies = <Map<String, dynamic>>[];
  final apiCalls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    if (options.path == '/auth/refresh-token') {
      refreshBodies.add(Map<String, dynamic>.from(options.data as Map));
      if (refreshHandler != null) return refreshHandler!(options);
      return _json(200, {
        'data': {
          'access_token': validAccessToken,
          'refresh_token': 'refresh-rotated',
        },
      });
    }
    final auth = options.headers['Authorization'];
    apiCalls.add('${options.method} ${options.path} $auth');
    if (alwaysUnauthorized || auth != 'Bearer $validAccessToken') {
      return _json(401, {'message': 'Unauthorized'});
    }
    return _json(200, {'ok': true, 'path': options.path});
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Future<void> _seedTokens({
  String accessKey = AppConstants.accessTokenKey,
  String? refresh = 'refresh-old',
}) async {
  await LocalStorage.instance.setSecure(accessKey, 'access-expired');
  if (refresh != null) {
    await LocalStorage.instance.setSecure(AppConstants.refreshTokenKey, refresh);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String?> expiredEvents;
  late int refreshedEvents;
  late List<StreamSubscription<Object?>> subs;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    AppConfig.instance.init(flavor: AppFlavor.passenger);
    ApiAvailabilityGuard.instance.reset();
    AuthSessionNotifier.instance.reset();
    ApiClient.instance.init();
    expiredEvents = [];
    refreshedEvents = 0;
    subs = [
      AuthSessionNotifier.instance.events.listen(expiredEvents.add),
      AuthSessionNotifier.instance.tokenRefreshedEvents.listen(
        (_) => refreshedEvents++,
      ),
    ];
  });

  tearDown(() async {
    for (final s in subs) {
      await s.cancel();
    }
    ApiAvailabilityGuard.instance.reset();
    AuthSessionNotifier.instance.reset();
  });

  test('a 401 triggers one refresh, persists rotated tokens and retries', () async {
    await _seedTokens();
    final backend = _FakeBackend();
    ApiClient.instance.dio.httpClientAdapter = backend;

    final response = await ApiClient.instance.dio.get('/rides/active');

    expect(response.statusCode, 200);
    expect(response.data['path'], '/rides/active');
    expect(backend.refreshBodies, [
      {'refreshToken': 'refresh-old'},
    ]);
    expect(backend.apiCalls, [
      'GET /rides/active Bearer access-expired',
      'GET /rides/active Bearer access-new',
    ]);
    expect(
      await LocalStorage.instance.getSecure(AppConstants.accessTokenKey),
      'access-new',
    );
    expect(
      await LocalStorage.instance.getSecure(AppConstants.refreshTokenKey),
      'refresh-rotated',
    );
    await pumpEventQueue();
    expect(refreshedEvents, 1);
    expect(expiredEvents, isEmpty);
  });

  test('retries POST with its original body after refresh', () async {
    await _seedTokens();
    final bodies = <Object?>[];
    final backend = _FakeBackend();
    ApiClient.instance.dio.httpClientAdapter = _Tap(backend, (options) {
      if (options.path == '/rides/maps/request') bodies.add(options.data);
    });

    final response = await ApiClient.instance.dio.post(
      '/rides/maps/request',
      data: {'pickup': 'Cocody'},
    );

    expect(response.statusCode, 200);
    expect(bodies, [
      {'pickup': 'Cocody'},
      {'pickup': 'Cocody'},
    ]);
  });

  test('accepts camelCase token keys from the refresh response', () async {
    await _seedTokens();
    final backend = _FakeBackend(
      refreshHandler: (_) async => _json(200, {
        'accessToken': 'access-new',
        'refreshToken': 'refresh-camel',
      }),
    );
    ApiClient.instance.dio.httpClientAdapter = backend;

    final response = await ApiClient.instance.dio.get('/profile');

    expect(response.statusCode, 200);
    expect(
      await LocalStorage.instance.getSecure(AppConstants.refreshTokenKey),
      'refresh-camel',
    );
  });

  test('concurrent 401s share a single refresh', () async {
    await _seedTokens();
    final gate = Completer<void>();
    final backend = _FakeBackend(
      refreshHandler: (_) async {
        await gate.future;
        return _json(200, {
          'data': {
            'access_token': 'access-new',
            'refresh_token': 'refresh-rotated',
          },
        });
      },
    );
    ApiClient.instance.dio.httpClientAdapter = backend;

    final futures = [
      ApiClient.instance.dio.get('/rides/active'),
      ApiClient.instance.dio.get('/profile'),
      ApiClient.instance.dio.get('/wallet'),
    ];
    // Laisse les trois 401 arriver pendant que le refresh est bloqué.
    for (var i = 0; i < 20 && backend.apiCalls.length < 3; i++) {
      await pumpEventQueue();
    }
    await pumpEventQueue();
    gate.complete();
    final responses = await Future.wait(futures);

    expect(responses.map((r) => r.statusCode), [200, 200, 200]);
    expect(backend.refreshBodies, hasLength(1));
    expect(
      backend.apiCalls.where((c) => c.endsWith('Bearer access-new')),
      hasLength(3),
    );
    await pumpEventQueue();
    expect(refreshedEvents, 1);
    expect(expiredEvents, isEmpty);
  });

  test('a rejected refresh logs the user out once and surfaces the 401', () async {
    await _seedTokens();
    final backend = _FakeBackend(
      refreshHandler: (_) async => _json(401, {'message': 'Refresh expired'}),
    );
    ApiClient.instance.dio.httpClientAdapter = backend;

    await expectLater(
      ApiClient.instance.dio.get('/rides/active'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    await expectLater(
      ApiClient.instance.dio.get('/profile'),
      throwsA(isA<DioException>()),
    );

    await pumpEventQueue();
    expect(backend.apiCalls, [
      'GET /rides/active Bearer access-expired',
      'GET /profile Bearer access-expired',
    ]);
    expect(expiredEvents, hasLength(1), reason: 'notifyExpired dédoublonné');
    expect(refreshedEvents, 0);
    expect(
      await LocalStorage.instance.getSecure(AppConstants.refreshTokenKey),
      'refresh-old',
    );
  });

  test('a missing refresh token logs the user out without calling refresh', () async {
    await _seedTokens(refresh: null);
    final backend = _FakeBackend();
    ApiClient.instance.dio.httpClientAdapter = backend;

    await expectLater(
      ApiClient.instance.dio.get('/rides/active'),
      throwsA(isA<DioException>()),
    );

    await pumpEventQueue();
    expect(backend.refreshBodies, isEmpty);
    expect(expiredEvents, hasLength(1));
  });

  test('a network failure during refresh keeps the session', () async {
    await _seedTokens();
    final backend = _FakeBackend(
      refreshHandler: (options) async => throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      ),
    );
    ApiClient.instance.dio.httpClientAdapter = backend;

    await expectLater(
      ApiClient.instance.dio.get('/rides/active'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );

    await pumpEventQueue();
    expect(backend.refreshBodies, hasLength(1));
    expect(expiredEvents, isEmpty);
    expect(
      await LocalStorage.instance.getSecure(AppConstants.refreshTokenKey),
      'refresh-old',
    );
  });

  test('a retry that is still 401 logs out without refreshing again', () async {
    await _seedTokens();
    final backend = _FakeBackend(alwaysUnauthorized: true);
    ApiClient.instance.dio.httpClientAdapter = backend;

    await expectLater(
      ApiClient.instance.dio.get('/rides/active'),
      throwsA(isA<DioException>()),
    );

    await pumpEventQueue();
    expect(backend.refreshBodies, hasLength(1));
    expect(backend.apiCalls, hasLength(2));
    expect(expiredEvents, hasLength(1));
  });

  test('401 on login is not treated as an expired session', () async {
    await _seedTokens();
    final backend = _FakeBackend(alwaysUnauthorized: true);
    ApiClient.instance.dio.httpClientAdapter = backend;

    await expectLater(
      ApiClient.instance.dio.post('/auth/login', data: {'phone': 'x'}),
      throwsA(isA<DioException>()),
    );

    await pumpEventQueue();
    expect(backend.refreshBodies, isEmpty);
    expect(expiredEvents, isEmpty);
  });

  test('401 without a stored access token does not refresh', () async {
    final backend = _FakeBackend();
    ApiClient.instance.dio.httpClientAdapter = backend;

    await expectLater(
      ApiClient.instance.dio.get('/rides/active'),
      throwsA(isA<DioException>()),
    );

    await pumpEventQueue();
    expect(backend.refreshBodies, isEmpty);
    expect(expiredEvents, isEmpty);
  });

  test('driver flavor refreshes into the driver token slot', () async {
    AppConfig.instance.init(flavor: AppFlavor.driver);
    ApiClient.instance.init();
    await _seedTokens(accessKey: AppConstants.driverAccessTokenKey);
    final backend = _FakeBackend();
    ApiClient.instance.dio.httpClientAdapter = backend;

    final response = await ApiClient.instance.dio.get('/drivers/me');

    expect(response.statusCode, 200);
    expect(
      await LocalStorage.instance.getSecure(AppConstants.driverAccessTokenKey),
      'access-new',
    );
    expect(
      await LocalStorage.instance.getSecure(AppConstants.accessTokenKey),
      isNull,
    );
  });
}

class _Tap implements HttpClientAdapter {
  _Tap(this._inner, this._onRequest);

  final HttpClientAdapter _inner;
  final void Function(RequestOptions options) _onRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    _onRequest(options);
    return _inner.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
