import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/data/sources/remote/driver_auth_remote_data_source.dart';

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
  group('DriverAuthRemoteDataSource', () {
    test('registerStep1 throws on semantic failure payload', () async {
      final dio = Dio()
        ..httpClientAdapter = RecordingHttpClientAdapter((
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
      final dataSource = DriverAuthRemoteDataSource(dio: dio);

      expect(
        () => dataSource.registerStep1('0700000000'),
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
      final dio = Dio()
        ..httpClientAdapter = RecordingHttpClientAdapter((
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
      final dataSource = DriverAuthRemoteDataSource(dio: dio);

      await dataSource.registerStep1('0700000000', email: 'driver@example.com');

      expect(capturedPayload, {
        'phoneNumber': '0700000000',
        'email': 'driver@example.com',
      });
    });

    test('registerStep2 throws on success false payload', () async {
      final dio = Dio()
        ..httpClientAdapter = RecordingHttpClientAdapter((
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
      final dataSource = DriverAuthRemoteDataSource(dio: dio);

      expect(
        () => dataSource.registerStep2('0700000000', '0000'),
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
      final dio = Dio()
        ..httpClientAdapter = RecordingHttpClientAdapter((
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
      final dataSource = DriverAuthRemoteDataSource(dio: dio);

      await dataSource.registerStep2('0700000000', '1234');
    });
  });
}
