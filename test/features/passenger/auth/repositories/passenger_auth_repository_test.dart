import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/services/auth_session_notifier.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
import 'package:fraya_mobile/data/sources/api_client.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    AppConfig.instance.init(flavor: AppFlavor.passenger);
    ApiClient.instance.init();
  });

  group('PassengerAuthRepository', () {
    test(
      'ApiClient emits tokenRefreshed after a successful 401 refresh',
      () async {
        await LocalStorage.instance.setSecure(
          AppConstants.accessTokenKey,
          'old',
        );
        await LocalStorage.instance.setSecure(
          AppConstants.refreshTokenKey,
          'refresh',
        );
        final tokenRefreshed = Completer<void>();
        final sub = AuthSessionNotifier.instance.tokenRefreshedEvents.listen((
          _,
        ) {
          if (!tokenRefreshed.isCompleted) tokenRefreshed.complete();
        });
        addTearDown(sub.cancel);

        var protectedCalls = 0;
        ApiClient.instance.dio.httpClientAdapter = RecordingHttpClientAdapter((
          options,
          requestStream,
          cancelFuture,
        ) async {
          await requestStream?.drain<void>();
          if (options.path == '/auth/refresh-token') {
            return ResponseBody.fromString(
              jsonEncode({
                'data': {'access_token': 'new'},
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          protectedCalls++;
          if (protectedCalls == 1) {
            return ResponseBody.fromString(
              jsonEncode({'message': 'Unauthorized'}),
              401,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          expect(options.headers['Authorization'], 'Bearer new');
          return ResponseBody.fromString(
            jsonEncode({'ok': true}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final response = await ApiClient.instance.dio.get('/protected');

        expect(response.statusCode, 200);
        await tokenRefreshed.future.timeout(const Duration(seconds: 1));
        expect(
          await LocalStorage.instance.getSecure(AppConstants.accessTokenKey),
          'new',
        );
      },
    );

    test('registerStep1 throws on semantic failure payload', () async {
      ApiClient.instance.dio.httpClientAdapter = RecordingHttpClientAdapter((
        options,
        requestStream,
        cancelFuture,
      ) async {
        await requestStream?.drain<void>();
        return ResponseBody.fromString(
          jsonEncode({'message': 'Utilisateur non trouve'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      final repository = PassengerAuthRepository(apiClient: ApiClient.instance);

      expect(
        () => repository.registerStep1('0700000000'),
        throwsA(
          isA<ServerException>().having(
            (error) => error.message,
            'message',
            'Utilisateur non trouve',
          ),
        ),
      );
    });

    test('registerStep1 sends phone and optional email payload', () async {
      Map<String, dynamic>? capturedPayload;
      ApiClient.instance.dio.httpClientAdapter = RecordingHttpClientAdapter((
        options,
        requestStream,
        cancelFuture,
      ) async {
        await requestStream?.drain<void>();
        capturedPayload = Map<String, dynamic>.from(options.data as Map);
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'message': 'Code envoye'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      final repository = PassengerAuthRepository(apiClient: ApiClient.instance);

      await repository.registerStep1('0700000000', email: 'client@example.com');

      expect(capturedPayload, {
        'phoneNumber': '0700000000',
        'email': 'client@example.com',
      });
    });

    test('registerStep2 throws on success false payload', () async {
      ApiClient.instance.dio.httpClientAdapter = RecordingHttpClientAdapter((
        options,
        requestStream,
        cancelFuture,
      ) async {
        await requestStream?.drain<void>();
        return ResponseBody.fromString(
          jsonEncode({'success': false, 'message': 'Code OTP invalide'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      final repository = PassengerAuthRepository(apiClient: ApiClient.instance);

      expect(
        () => repository.registerStep2('0700000000', '0000'),
        throwsA(
          isA<ServerException>().having(
            (error) => error.message,
            'message',
            'Code OTP invalide',
          ),
        ),
      );
    });

    test('registerStep2 succeeds when payload confirms success', () async {
      ApiClient.instance.dio.httpClientAdapter = RecordingHttpClientAdapter((
        options,
        requestStream,
        cancelFuture,
      ) async {
        await requestStream?.drain<void>();
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'message': 'Code valide'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      final repository = PassengerAuthRepository(apiClient: ApiClient.instance);

      await repository.registerStep2('0700000000', '1234');
    });
  });
}
