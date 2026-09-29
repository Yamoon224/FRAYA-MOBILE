import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/data/sources/remote/driver_vehicle_remote_data_source.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_submission.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_update.dart';

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
  group('DriverVehicleRemoteDataSource', () {
    late Directory tempDir;
    late DriverVehicleSubmission submission;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('driver-vehicle-test');
      submission = DriverVehicleSubmission(
        brand: 'Toyota',
        model: 'Corolla',
        year: '2022',
        color: 'Rouge',
        licensePlate: '12ERSTDFD',
        range: 'MAGIC',
        sidUserId: 9,
        kycDocuments: {
          for (final type in _requiredKycDocuments)
            type: await _createKycDocument(tempDir, type),
        },
        documents: {
          for (final type in DriverVehicleDocumentType.values)
            type: await _createDocument(tempDir, type),
        },
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        try {
          await tempDir.delete(recursive: true);
        } on PathAccessException {
          // Le stream multipart peut encore etre en train de liberer les handles
          // fichiers sous Windows au moment du tearDown.
        }
      }
    });

    test('sends multipart payload with forced pending status', () async {
      FormData? capturedFormData;
      RequestOptions? capturedOptions;
      final dio = Dio()
        ..httpClientAdapter = RecordingHttpClientAdapter((
          options,
          requestStream,
          cancelFuture,
        ) async {
          await requestStream?.drain<void>();
          capturedOptions = options;
          capturedFormData = options.data as FormData;
          return ResponseBody.fromString(
            jsonEncode({'id': 12}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });
      final dataSource = DriverVehicleRemoteDataSource(dio: dio);

      final response = await dataSource.submitVehicle(submission: submission);

      expect(response['id'], 12);
      expect(capturedOptions?.path, '/vehicles/create');
      expect(capturedOptions?.contentType, startsWith('multipart/form-data'));
      expect(
        Map<String, String>.fromEntries(capturedFormData!.fields),
        containsPair('brand', 'Toyota'),
      );
      expect(
        Map<String, String>.fromEntries(capturedFormData!.fields),
        containsPair('model', 'Corolla'),
      );
      expect(
        Map<String, String>.fromEntries(capturedFormData!.fields),
        containsPair('year', '2022'),
      );
      expect(
        Map<String, String>.fromEntries(capturedFormData!.fields),
        containsPair('color', 'Rouge'),
      );
      expect(
        Map<String, String>.fromEntries(capturedFormData!.fields),
        containsPair('licensePlate', '12ERSTDFD'),
      );
      expect(
        Map<String, String>.fromEntries(capturedFormData!.fields),
        containsPair('range', 'MAGIC'),
      );
      expect(
        Map<String, String>.fromEntries(capturedFormData!.fields),
        containsPair('sidUserId', '9'),
      );
      expect(
        Map<String, String>.fromEntries(capturedFormData!.fields),
        containsPair('vehicleStatus', 'PENDING_VALIDATION'),
      );
      expect(capturedFormData!.files.map((entry) => entry.key).toSet(), {
        'insuranceCertificate',
        'technicalInspection',
        'vehicleRegistration',
        'photoFrontVehicle',
        'photoRearVehicle',
        'photoLeftVehicle',
        'photoRightVehicle',
        'photoInteriorVehicle',
        ..._requiredKycDocuments.map((type) => type.backendField),
      });
    });

    test('sends patch payload for descriptive vehicle update', () async {
      RequestOptions? capturedOptions;
      Map<String, dynamic>? capturedData;
      final dio = Dio()
        ..httpClientAdapter = RecordingHttpClientAdapter((
          options,
          requestStream,
          cancelFuture,
        ) async {
          capturedOptions = options;
          capturedData = Map<String, dynamic>.from(
            options.data as Map<String, dynamic>,
          );
          return ResponseBody.fromString(
            jsonEncode({'id': 12, 'vehicleStatus': 'PENDING_VALIDATION'}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });
      final dataSource = DriverVehicleRemoteDataSource(dio: dio);

      final response = await dataSource.updateVehicle(
        vehicleId: 12,
        update: const DriverVehicleUpdate(
          brand: 'Toyota',
          model: 'Corolla',
          year: '2027',
          color: 'Rouge',
          licensePlate: '12ERSTDFD',
          range: 'magic',
          airConditioning: true,
          sidUserId: 9,
        ),
      );

      expect(response['id'], 12);
      expect(capturedOptions?.method, 'PATCH');
      expect(capturedOptions?.path, '/vehicles/12');
      expect(capturedData, containsPair('brand', 'Toyota'));
      expect(capturedData, containsPair('year', 2027));
      expect(capturedData, containsPair('range', 'MAGIC'));
      expect(capturedData, containsPair('airConditioning', true));
      expect(capturedData, containsPair('vehicleStatus', 'PENDING_VALIDATION'));
      expect(capturedData, containsPair('sidUserId', 9));
    });

    test(
      'throws server exception when response payload is not a map',
      () async {
        final dio = Dio()
          ..httpClientAdapter = RecordingHttpClientAdapter((
            options,
            requestStream,
            cancelFuture,
          ) async {
            await requestStream?.drain<void>();
            return ResponseBody.fromString(
              jsonEncode(['unexpected']),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          });
        final dataSource = DriverVehicleRemoteDataSource(dio: dio);

        expect(
          () => dataSource.submitVehicle(submission: submission),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test('maps dio bad responses through api client error handler', () async {
      final dio = Dio()
        ..httpClientAdapter = RecordingHttpClientAdapter((
          options,
          requestStream,
          cancelFuture,
        ) async {
          await requestStream?.drain<void>();
          throw DioException.badResponse(
            statusCode: 422,
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 422,
              data: {
                'message': 'validation error',
                'errors': {'licensePlate': 'Plaque invalide.'},
              },
            ),
          );
        });
      final dataSource = DriverVehicleRemoteDataSource(dio: dio);

      expect(
        () => dataSource.submitVehicle(submission: submission),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

const List<DriverKycDocumentType> _requiredKycDocuments = [
  DriverKycDocumentType.photoFrontPermis,
  DriverKycDocumentType.photoBackPermis,
  DriverKycDocumentType.photoSelfPermis,
];

Future<DriverKycDocumentFile> _createDocument(
  Directory tempDir,
  DriverVehicleDocumentType type,
) async {
  final fileName = switch (type) {
    DriverVehicleDocumentType.insuranceCertificate => 'insurance.pdf',
    DriverVehicleDocumentType.technicalInspection => 'inspection.pdf',
    DriverVehicleDocumentType.vehicleRegistration => 'registration.pdf',
    DriverVehicleDocumentType.photoFrontVehicle => 'vehicle-front.png',
    DriverVehicleDocumentType.photoRearVehicle => 'vehicle-rear.png',
    DriverVehicleDocumentType.photoLeftVehicle => 'vehicle-left.png',
    DriverVehicleDocumentType.photoRightVehicle => 'vehicle-right.png',
    DriverVehicleDocumentType.photoInteriorVehicle => 'vehicle-interior.png',
  };
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsBytes(const [1, 2, 3, 4]);
  return DriverKycDocumentFile.fromPath(
    path: file.path,
    fileName: fileName,
    source: fileName.endsWith('.png')
        ? DriverKycDocumentSource.galleryImage
        : DriverKycDocumentSource.pdfFile,
  )!;
}

Future<DriverKycDocumentFile> _createKycDocument(
  Directory tempDir,
  DriverKycDocumentType type,
) async {
  final fileName = '${type.backendField}.png';
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsBytes(const [9, 8, 7, 6]);
  return DriverKycDocumentFile.fromPath(
    path: file.path,
    fileName: fileName,
    source: DriverKycDocumentSource.galleryImage,
  )!;
}
