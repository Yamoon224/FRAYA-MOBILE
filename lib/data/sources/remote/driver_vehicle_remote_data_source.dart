library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/utils/constants.dart';
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
      final fields = <String, dynamic>{
        'brand': submission.brand,
        'model': submission.model,
        'year': submission.year,
        'color': submission.color,
        'licensePlate': submission.licensePlate,
        'range': submission.range,
        if (submission.secondaryRange != null && submission.secondaryRange!.isNotEmpty)
          'secondaryRange': submission.secondaryRange,
        'sidUserId': submission.sidUserId.toString(),
        'vehicleStatus': 'PENDING_VALIDATION',
        'airConditioning': submission.airConditioning,
      };

      final documents = <String, DriverKycDocumentFile>{};
      for (final type in _requiredKycDocuments) {
        final document = submission.kycDocuments[type];
        if (document == null) {
          continue;
        }
        documents[type.backendField] = document;
      }
      for (final entry in submission.documents.entries) {
        documents[entry.key.backendField] = entry.value;
      }

      final response = await _postWithRetry(
        '/vehicles/create',
        fields: fields,
        documents: documents,
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

  /// Retire la seconde gamme ou la remplace par une gamme déjà couverte (libre-service).
  Future<Map<String, dynamic>> updateSecondaryRange({
    required int vehicleId,
    required String? secondaryRange,
  }) async {
    try {
      final response = await _dio.patch(
        '/vehicles/$vehicleId/secondary-range',
        data: {'secondaryRange': secondaryRange},
      );
      return _parseResponse(response, 'mise à jour de la seconde gamme');
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(
        message: 'Impossible de mettre à jour la seconde gamme : $error',
      );
    }
  }

  /// Demande une seconde gamme supérieure à la principale : les cinq photos sont jointes
  /// et un administrateur examine la demande. Le véhicule reste en service pendant la revue.
  Future<Map<String, dynamic>> requestSecondaryRange({
    required int vehicleId,
    required String secondaryRange,
    required Map<DriverVehicleDocumentType, DriverKycDocumentFile> photos,
  }) async {
    try {
      final response = await _postWithRetry(
        '/vehicles/$vehicleId/change-requests',
        fields: {'secondaryRange': secondaryRange},
        documents: {
          for (final entry in photos.entries) entry.key.backendField: entry.value,
        },
      );
      return _parseResponse(response, 'demande de seconde gamme');
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(
        message: "Impossible d'envoyer la demande de seconde gamme : $error",
      );
    }
  }

  /// Envoie la requête multipart ; si l'upload échoue par timeout réseau
  /// (fréquent avec plusieurs photos sur une connexion mobile lente), on
  /// reconstruit le FormData (les MultipartFile ne sont utilisables qu'une
  /// fois) et on retente une seule fois avant de remonter l'erreur.
  Future<Response<dynamic>> _postWithRetry(
    String path, {
    required Map<String, dynamic> fields,
    required Map<String, DriverKycDocumentFile> documents,
  }) async {
    const maxAttempts = 2;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final formData = await _buildFormData(fields, documents);
        return await _dio.post(
          path,
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
            sendTimeout: AppConstants.uploadSendTimeout,
            receiveTimeout: AppConstants.uploadReceiveTimeout,
          ),
        );
      } on DioException catch (error) {
        final isTimeout =
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionTimeout;
        if (!isTimeout || attempt == maxAttempts) {
          rethrow;
        }
      }
    }
    throw StateError('unreachable');
  }

  Future<FormData> _buildFormData(
    Map<String, dynamic> fields,
    Map<String, DriverKycDocumentFile> documents,
  ) async {
    final payload = <String, dynamic>{...fields};
    for (final entry in documents.entries) {
      payload[entry.key] = await MultipartFile.fromFile(
        entry.value.path,
        filename: entry.value.fileName,
        contentType: DioMediaType.parse(entry.value.mimeType),
      );
    }
    return FormData.fromMap(payload);
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
];
