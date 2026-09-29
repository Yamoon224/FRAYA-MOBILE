library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../domain/models/driver_kyc_document_file.dart';
import '../../../domain/models/driver_kyc_document_type.dart';
import '../../../domain/models/driver_vehicle_submission.dart';
import '../../../domain/models/driver_vehicle_document_type.dart';
import '../../../domain/models/driver_vehicle_update.dart';
import '../../sources/api_client.dart';

class DriverVehicleRemoteDataSource {
  DriverVehicleRemoteDataSource({Dio? dio})
    : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<Map<String, dynamic>> submitVehicle({
    required DriverVehicleSubmission submission,
  }) async {
    try {
      final payload = <String, dynamic>{
        'brand': submission.brand,
        'model': submission.model,
        'year': submission.year,
        'color': submission.color,
        'licensePlate': submission.licensePlate,
        'range': submission.range,
        'sidUserId': submission.sidUserId.toString(),
        'vehicleStatus': 'PENDING_VALIDATION',
        'airConditioning': submission.airConditioning,
      };

      for (final type in _requiredKycDocuments) {
        final document = submission.kycDocuments[type];
        if (document == null) {
          continue;
        }
        payload[type.backendField] = await MultipartFile.fromFile(
          document.path,
          filename: document.fileName,
          contentType: DioMediaType.parse(document.mimeType),
        );
      }

      await _appendVehicleDocuments(payload, submission.documents);

      final response = await _dio.post(
        '/vehicles/create',
        data: FormData.fromMap(payload),
        options: Options(contentType: 'multipart/form-data'),
      );

      return _parseResponse(response, 'création du véhicule');
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: 'Impossible d\'enregistrer le véhicule : $error',
      );
    }
  }

  Future<Map<String, dynamic>> updateVehicle({
    required int vehicleId,
    required DriverVehicleUpdate update,
  }) async {
    try {
      final response = await _dio.patch(
        '/vehicles/$vehicleId',
        data: update.toJson(),
      );

      return _parseResponse(response, 'mise Ã  jour du vÃ©hicule');
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: 'Impossible de mettre Ã  jour le vÃ©hicule : $error',
      );
    }
  }

  Future<void> _appendVehicleDocuments(
    Map<String, dynamic> payload,
    Map<DriverVehicleDocumentType, DriverKycDocumentFile> documents,
  ) async {
    for (final entry in documents.entries) {
      final document = entry.value;
      payload[entry.key.backendField] = await MultipartFile.fromFile(
        document.path,
        filename: document.fileName,
        contentType: DioMediaType.parse(document.mimeType),
      );
    }
  }

  Map<String, dynamic> _parseResponse(Response<dynamic> response, String op) {
    if (response.data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(response.data as Map<String, dynamic>);
    }
    throw ServerException(message: 'Réponse serveur invalide lors de la $op.');
  }
}

const List<DriverKycDocumentType> _requiredKycDocuments = [
  DriverKycDocumentType.photoFrontPermis,
  DriverKycDocumentType.photoBackPermis,
  DriverKycDocumentType.photoSelfPermis,
];
