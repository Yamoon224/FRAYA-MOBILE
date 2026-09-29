library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/utils/auth_step_response_validator.dart';
import '../../../core/utils/auth_log_redactor.dart';
import '../../../core/utils/logger.dart';
import '../../sources/api_client.dart';

class DriverAuthRemoteDataSource {
  DriverAuthRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    return _post(
      '/auth/login',
      data: {'phoneNumber': phoneNumber, 'password': password},
    );
  }

  Future<void> registerStep1(String phoneNumber, {String? email}) async {
    final payload = <String, dynamic>{'phoneNumber': phoneNumber};
    if (email != null && email.trim().isNotEmpty) {
      payload['email'] = email.trim();
    }
    await _postVoid('/auth/register/step1', data: payload);
  }

  Future<void> registerStep2(
    String phoneNumber,
    String verificationCode,
  ) async {
    await _postVoid(
      '/auth/register/step2',
      data: {'phoneNumber': phoneNumber, 'verificationCode': verificationCode},
    );
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    return _post(
      '/auth/register/step3',
      data: userData,
      logLabel: '[AUTH_REGISTER_STEP3] Driver',
    );
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final response = await _dio.get('/sid-users/profile');
      return _mapResponse(response.data);
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: 'Impossible de récupérer le profil chauffeur : $error',
      );
    }
  }

  Future<void> _postVoid(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      ensureAuthStepSucceeded(
        response.data,
        fallbackMessage:
            'La validation de cette étape d\'authentification a échoué.',
      );
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) {
        rethrow;
      }
      throw ServerException(
        message:
            'Impossible d\'exécuter l\'authentification chauffeur : $error',
      );
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> data,
    String? logLabel,
  }) async {
    if (logLabel != null) {
      logger.warning('$logLabel payload: ${redactAuthLogData(data)}');
    }
    try {
      final response = await _dio.post(path, data: data);
      if (logLabel != null) {
        logger.warning(
          '$logLabel response: status=${response.statusCode} '
          'data=${redactAuthLogData(response.data)}',
        );
      }
      return _mapResponse(response.data);
    } on DioException catch (error) {
      if (logLabel != null) {
        logger.warning(
          '$logLabel error: status=${error.response?.statusCode} '
          'data=${redactAuthLogData(error.response?.data)}',
        );
      }
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) {
        rethrow;
      }
      throw ServerException(
        message:
            'Impossible d\'exécuter l\'authentification chauffeur : $error',
      );
    }
  }

  Map<String, dynamic> _mapResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    throw const ServerException(
      message: 'Réponse serveur invalide pour l\'authentification chauffeur.',
    );
  }
}
