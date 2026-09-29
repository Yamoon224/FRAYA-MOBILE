import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/remote/driver_kyc_remote_data_source.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_submission.dart';

class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter(this._handler);

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
  group('DriverKycRemoteDataSource', () {
    test(
      'omits the optional criminal record when it is not selected',
      () async {
        FormData? capturedFormData;
        final document = await _temporaryDocument('front-license.jpg');
        final dio = Dio()
          ..httpClientAdapter = _RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            capturedFormData = options.data as FormData;
            await requestStream?.drain<void>();
            return _successResponse();
          });

        await DriverKycRemoteDataSource(dio: dio).submitKyc(
          userId: 14,
          submission: DriverKycSubmission(
            documents: {DriverKycDocumentType.photoFrontPermis: document},
          ),
        );

        final fileKeys = capturedFormData!.files.map((entry) => entry.key);
        expect(fileKeys, contains('photoFrontPermis'));
        expect(fileKeys, isNot(contains('photoCasier')));
      },
    );

    test('includes the criminal record when it is selected', () async {
      FormData? capturedFormData;
      final document = await _temporaryDocument('criminal-record.jpg');
      final dio = Dio()
        ..httpClientAdapter = _RecordingHttpClientAdapter((
          options,
          requestStream,
          cancelFuture,
        ) async {
          capturedFormData = options.data as FormData;
          await requestStream?.drain<void>();
          return _successResponse();
        });

      await DriverKycRemoteDataSource(dio: dio).submitKyc(
        userId: 14,
        submission: DriverKycSubmission(
          documents: {DriverKycDocumentType.photoCasier: document},
        ),
      );

      expect(
        capturedFormData!.files.map((entry) => entry.key),
        contains('photoCasier'),
      );
    });

    test('fetches KYC details by sid user id', () async {
      RequestOptions? capturedOptions;
      final dio = Dio()
        ..httpClientAdapter = _RecordingHttpClientAdapter((
          options,
          requestStream,
          cancelFuture,
        ) async {
          capturedOptions = options;
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 6,
                  'sidUserId': 37,
                  'status': 'CANCEL',
                  'description': 'Permis non conformes',
                },
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });
      final dataSource = DriverKycRemoteDataSource(dio: dio);

      final response = await dataSource.getKycBySidUser(sidUserId: 37);

      expect(capturedOptions?.method, 'GET');
      expect(capturedOptions?.path, '/kycs/sid-user/37');
      expect(response['data'], isA<List<dynamic>>());
    });
  });
}

Future<DriverKycDocumentFile> _temporaryDocument(String fileName) async {
  final directory = await Directory.systemTemp.createTemp('fraya_kyc_test_');
  addTearDown(() => directory.delete(recursive: true));
  final file = await File(
    '${directory.path}/$fileName',
  ).writeAsBytes([1, 2, 3]);
  return DriverKycDocumentFile.fromPath(
    path: file.path,
    fileName: fileName,
    source: DriverKycDocumentSource.galleryImage,
  )!;
}

ResponseBody _successResponse() {
  return ResponseBody.fromString(
    jsonEncode({'success': true, 'data': {}}),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
