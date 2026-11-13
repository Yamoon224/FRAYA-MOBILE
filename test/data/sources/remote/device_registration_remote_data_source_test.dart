import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
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
      'register envoie jeton, plateforme et rôle à /devices/register',
      () async {
        RequestOptions? captured;
        final dataSource = DeviceRegistrationRemoteDataSource(
          dio: Dio()
            ..httpClientAdapter = RecordingHttpClientAdapter((
              options,
              requestStream,
              cancelFuture,
            ) async {
              captured = options;
              return _jsonResponse({'success': true}, 201);
            }),
        );

        await dataSource.register(_registration);

        expect(captured?.method, 'POST');
        expect(captured?.path, '/devices/register');
        // Pas d'identifiant utilisateur : le serveur le déduit de l'authentification.
        expect(captured?.data, {
          'token': 'fcm-token-abc',
          'platform': 'android',
          'role': 'DRIVER',
        });
      },
    );

    test(
      'deactivate envoie seulement le jeton à /devices/deactivate',
      () async {
        RequestOptions? captured;
        final dataSource = DeviceRegistrationRemoteDataSource(
          dio: Dio()
            ..httpClientAdapter = RecordingHttpClientAdapter((
              options,
              requestStream,
              cancelFuture,
            ) async {
              captured = options;
              return _jsonResponse({}, 204);
            }),
        );

        await dataSource.deactivate(_registration);

        expect(captured?.path, '/devices/deactivate');
        expect(captured?.data, {'token': 'fcm-token-abc'});
      },
    );

    test('une réponse inattendue lève une erreur serveur', () async {
      final dataSource = DeviceRegistrationRemoteDataSource(
        dio: Dio()
          ..httpClientAdapter = RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            return _jsonResponse({}, 202);
          }),
      );

      await expectLater(
        dataSource.register(_registration),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('DeviceRegistration', () {
    test('la sérialisation locale garde l utilisateur et se relit', () {
      expect(
        DeviceRegistration.fromJson(_registration.toJson()),
        _registration,
      );
    });

    test('un enregistrement sans jeton est ignoré', () {
      expect(
        DeviceRegistration.fromJson({
          'userId': '1',
          'role': 'DRIVER',
          'platform': 'ios',
        }),
        isNull,
      );
    });
  });
}

const _registration = DeviceRegistration(
  userId: '24',
  role: 'DRIVER',
  pushToken: 'fcm-token-abc',
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
