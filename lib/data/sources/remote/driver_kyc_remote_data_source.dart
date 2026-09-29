library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../domain/models/driver_kyc_document_file.dart';
import '../../../domain/models/driver_kyc_document_type.dart';
import '../../sources/api_client.dart';
import '../../../domain/models/driver_kyc_submission.dart';

class DriverKycRemoteDataSource {
  DriverKycRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<Map<String, dynamic>> submitKyc({
    required int userId,
    required DriverKycSubmission submission,
  }) async {
    try {
      final payload = await _buildDocumentPayload(submission.documents);

      final response = await _dio.post(
        '/kycs/create/$userId',
        data: FormData.fromMap(payload),
        options: Options(contentType: 'multipart/form-data'),
      );

      return _parseResponse(response, 'soumission KYC');
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(
        message: 'Impossible de soumettre le dossier KYC : $error',
      );
    }
  }

  Future<Map<String, dynamic>> updateKyc({
    required int kycId,
    required Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
  }) async {
    try {
      final payload = await _buildDocumentPayload(documents);

      final response = await _dio.post(
        '/kycs/update/$kycId',
        data: FormData.fromMap(payload),
        options: Options(contentType: 'multipart/form-data'),
      );

      return _parseResponse(response, 'mise à jour KYC');
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(
        message: 'Impossible de mettre à jour le dossier KYC : $error',
      );
    }
  }

  Future<Map<String, dynamic>> getKycBySidUser({required int sidUserId}) async {
    try {
      final response = await _dio.get('/kycs/sid-user/$sidUserId');
      return _parseResponse(response, 'récupération du dossier KYC');
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(
        message: 'Impossible de récupérer le dossier KYC : $error',
      );
    }
  }

  Future<Map<String, dynamic>> _buildDocumentPayload(
    Map<DriverKycDocumentType, DriverKycDocumentFile> documents,
  ) async {
    final payload = <String, dynamic>{};
    for (final entry in documents.entries) {
      payload[entry.key.backendField] = await MultipartFile.fromFile(
        entry.value.path,
        filename: entry.value.fileName,
        contentType: DioMediaType.parse(entry.value.mimeType),
      );
    }
    return payload;
  }

  Map<String, dynamic> _parseResponse(Response<dynamic> response, String op) {
    if (response.data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(response.data as Map<String, dynamic>);
    }
    throw ServerException(message: 'Réponse serveur invalide lors de la $op.');
  }
}
