import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/data/repositories/forgot_password_repository.dart';
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
    ApiClient.instance.init();
  });

  group('ForgotPasswordRepository', () {
    test('sendResetCode sends CLIENT type for passenger flavor', () async {
      Map<String, dynamic>? capturedPayload;
      String? capturedPath;
      ApiClient.instance.dio.httpClientAdapter = _RecordingHttpClientAdapter((
        options,
      ) async {
        capturedPath = options.path;
        capturedPayload = Map<String, dynamic>.from(options.data as Map);
        return _ok();
      });
      final repository = ForgotPasswordRepository(
        apiClient: ApiClient.instance,
      );

      await repository.sendResetCode('0700000000');

      expect(capturedPath, '/auth/forgot-password');
      expect(capturedPayload, {'phoneNumber': '0700000000', 'type': 'CLIENT'});
    });

    test('sendResetCode sends DRIVER type for driver flavor', () async {
      AppConfig.instance.init(flavor: AppFlavor.driver);
      ApiClient.instance.init();
      Map<String, dynamic>? capturedPayload;
      ApiClient.instance.dio.httpClientAdapter = _RecordingHttpClientAdapter((
        options,
      ) async {
        capturedPayload = Map<String, dynamic>.from(options.data as Map);
        return _ok();
      });
      final repository = ForgotPasswordRepository(
        apiClient: ApiClient.instance,
      );

      await repository.sendResetCode('driver@example.com');

      expect(capturedPayload, {
        'email': 'driver@example.com',
        'type': 'DRIVER',
      });
    });

    test(
      'sendResetCode rejects a business failure returned with HTTP 200',
      () async {
        ApiClient.instance.dio.httpClientAdapter = _respondingAdapter({
          'success': false,
          'message': 'Aucun client trouvé avec cet email',
        });
        final repository = ForgotPasswordRepository(
          apiClient: ApiClient.instance,
        );

        expect(
          () => repository.sendResetCode('client@example.com'),
          throwsA(
            isA<ServerException>().having(
              (error) => error.message,
              'message',
              'Aucun client trouvé avec cet email',
            ),
          ),
        );
      },
    );

    test('sendResetCode preserves the backend message for HTTP 500', () async {
      ApiClient.instance.dio.httpClientAdapter = _respondingAdapter({
        'success': false,
        'message': 'Aucun client trouvé avec cet email',
        'statusCode': 500,
        'error': {
          'code': 'DATABASE_ERROR',
          'detail': 'Aucun client trouvé avec cet email',
        },
      }, statusCode: 500);
      final repository = ForgotPasswordRepository(
        apiClient: ApiClient.instance,
      );

      expect(
        () => repository.sendResetCode('client@example.com'),
        throwsA(
          isA<ServerException>().having(
            (error) => error.message,
            'message',
            'Aucun client trouvé avec cet email',
          ),
        ),
      );
    });

    test(
      'resetPassword rejects a business failure returned with HTTP 200',
      () async {
        ApiClient.instance.dio.httpClientAdapter = _respondingAdapter({
          'success': false,
          'message': 'Code de vérification invalide',
        });
        final repository = ForgotPasswordRepository(
          apiClient: ApiClient.instance,
        );

        expect(
          () => repository.resetPassword('1234', 'new-password'),
          throwsA(
            isA<ServerException>().having(
              (error) => error.message,
              'message',
              'Code de vérification invalide',
            ),
          ),
        );
      },
    );

    test('resetPassword accepts a successful response', () async {
      ApiClient.instance.dio.httpClientAdapter = _respondingAdapter({
        'success': true,
      });
      final repository = ForgotPasswordRepository(
        apiClient: ApiClient.instance,
      );

      await repository.resetPassword('1234', 'new-password');
    });
  });
}

HttpClientAdapter _respondingAdapter(
  Map<String, dynamic> payload, {
  int statusCode = 200,
}) {
  return _RecordingHttpClientAdapter(
    (_) async => ResponseBody.fromString(
      jsonEncode(payload),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    ),
  );
}

ResponseBody _ok() {
  return ResponseBody.fromString(
    jsonEncode({'success': true}),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
