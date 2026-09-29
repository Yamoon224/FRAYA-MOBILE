import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/data/sources/remote/driver_profile_remote_data_source.dart';
import 'package:fraya_mobile/data/sources/remote/passenger_profile_remote_data_source.dart';

class _RecordedRequest {
  const _RecordedRequest({
    required this.method,
    required this.path,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, dynamic> body;
}

class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter({this.statusCode = 200, this.responseBody = ''});

  final int statusCode;
  final String responseBody;
  final requests = <_RecordedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      _RecordedRequest(
        method: options.method,
        path: options.path,
        body: await _decodeRequestBody(requestStream),
      ),
    );
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const phoneNumber = '+2250700000000';

  group('PassengerProfileRemoteDataSource phone change', () {
    test('sends the phone change contracts expected by the backend', () async {
      final adapter = _RecordingHttpClientAdapter();
      final dataSource = PassengerProfileRemoteDataSource(
        dio: Dio()..httpClientAdapter = adapter,
      );

      await dataSource.requestPhoneChange(phoneNumber);
      await dataSource.confirmPhoneChange('1234');

      _expectPhoneChangeRequests(adapter.requests, phoneNumber);
    });

    test(
      'preserves a duplicate phone conflict returned with HTTP 409',
      () async {
        final adapter = _duplicatePhoneAdapter(statusCode: 409);
        final dataSource = PassengerProfileRemoteDataSource(
          dio: Dio()..httpClientAdapter = adapter,
        );

        await expectLater(
          dataSource.requestPhoneChange(phoneNumber),
          throwsA(_isDuplicatePhoneConflict()),
        );

        expect(adapter.requests, hasLength(1));
      },
    );

    test(
      'rejects a duplicate phone failure envelope returned with 200',
      () async {
        final adapter = _duplicatePhoneAdapter(statusCode: 200);
        final dataSource = PassengerProfileRemoteDataSource(
          dio: Dio()..httpClientAdapter = adapter,
        );

        await expectLater(
          dataSource.requestPhoneChange(phoneNumber),
          throwsA(_isDuplicatePhoneConflict()),
        );
      },
    );
  });

  group('DriverProfileRemoteDataSource phone change', () {
    test('sends the phone change contracts expected by the backend', () async {
      final adapter = _RecordingHttpClientAdapter();
      final dataSource = DriverProfileRemoteDataSource(
        dio: Dio()..httpClientAdapter = adapter,
      );

      await dataSource.requestPhoneChange(phoneNumber);
      await dataSource.confirmPhoneChange('1234');

      _expectPhoneChangeRequests(adapter.requests, phoneNumber);
    });

    test(
      'preserves a duplicate phone conflict returned with HTTP 409',
      () async {
        final adapter = _duplicatePhoneAdapter(statusCode: 409);
        final dataSource = DriverProfileRemoteDataSource(
          dio: Dio()..httpClientAdapter = adapter,
        );

        await expectLater(
          dataSource.requestPhoneChange(phoneNumber),
          throwsA(_isDuplicatePhoneConflict()),
        );

        expect(adapter.requests, hasLength(1));
      },
    );
  });
}

_RecordingHttpClientAdapter _duplicatePhoneAdapter({required int statusCode}) {
  return _RecordingHttpClientAdapter(
    statusCode: statusCode,
    responseBody: jsonEncode({
      'success': false,
      'statusCode': 409,
      'message': 'Ce numéro de téléphone est déjà utilisé',
    }),
  );
}

Matcher _isDuplicatePhoneConflict() {
  return isA<ServerException>()
      .having((error) => error.statusCode, 'statusCode', 409)
      .having(
        (error) => error.message,
        'message',
        'Ce numéro de téléphone est déjà utilisé',
      );
}

void _expectPhoneChangeRequests(
  List<_RecordedRequest> requests,
  String phoneNumber,
) {
  expect(requests, hasLength(2));
  expect(requests.first.method, 'POST');
  expect(requests.first.path, '/sid-users/request-phone-change');
  expect(requests.first.body, {'newPhoneNumber': phoneNumber});
  expect(requests.last.method, 'POST');
  expect(requests.last.path, '/sid-users/confirm-phone-change');
  expect(requests.last.body, {'verificationCode': '1234'});
}

Future<Map<String, dynamic>> _decodeRequestBody(
  Stream<Uint8List>? requestStream,
) async {
  if (requestStream == null) return const {};

  final bytes = BytesBuilder(copy: false);
  await for (final chunk in requestStream) {
    bytes.add(chunk);
  }
  final content = utf8.decode(bytes.takeBytes());
  return Map<String, dynamic>.from(jsonDecode(content) as Map);
}
