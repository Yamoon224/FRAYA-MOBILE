library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/utils/auth_step_response_validator.dart';
import '../../sources/api_client.dart';

class PassengerProfileRemoteDataSource {
  PassengerProfileRemoteDataSource({Dio? dio})
    : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/sid-users/profile');
      return _asMap(response.data);
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible de charger le profil : $error',
      );
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.put(
        '/sid-users/update-info/$userId',
        data: data,
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible de mettre à jour le profil : $error',
      );
    }
  }

  Future<Map<String, dynamic>> updateProfilePhoto({
    required int userId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final payload = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _dio.put(
        '/sid-users/update-info/$userId',
        data: payload,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data == null || data == '') return {};
      return _asMap(data);
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible de mettre à jour la photo de profil : $error',
      );
    }
  }

  Future<void> requestPhoneChange(String newPhoneNumber) async {
    try {
      final response = await _dio.post(
        '/sid-users/request-phone-change',
        data: {'newPhoneNumber': newPhoneNumber},
      );
      ensureAuthStepSucceeded(
        response.data,
        fallbackMessage: "Impossible d'envoyer le code OTP.",
      );
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(
        message: "Impossible d'envoyer le code OTP : $error",
      );
    }
  }

  Future<void> confirmPhoneChange(String verificationCode) async {
    try {
      final response = await _dio.post(
        '/sid-users/confirm-phone-change',
        data: {'verificationCode': verificationCode},
      );
      ensureAuthStepSucceeded(
        response.data,
        fallbackMessage: 'Impossible de confirmer le changement de numéro.',
      );
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(message: 'Code OTP invalide : $error');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw const ServerException(message: 'Format de reponse API inattendu.');
  }
}
