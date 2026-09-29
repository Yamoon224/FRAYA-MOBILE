import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/utils/auth_step_response_validator.dart';
import '../../../core/utils/auth_log_redactor.dart';
import '../../../core/utils/logger.dart';
import '../api_client.dart';

class PassengerAuthRemoteDataSource {
  PassengerAuthRemoteDataSource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'phoneNumber': phoneNumber, 'password': password},
      );
      return _mapResponse(response.data);
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    }
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

  Future<Map<String, dynamic>> registerStep3(
    Map<String, dynamic> userData,
  ) async {
    logger.warning(
      '[AUTH_REGISTER_STEP3] Passenger payload: '
      '${redactAuthLogData(userData)}',
    );
    try {
      final response = await _dio.post('/auth/register/step3', data: userData);
      logger.warning(
        '[AUTH_REGISTER_STEP3] Passenger response: '
        'status=${response.statusCode} '
        'data=${redactAuthLogData(response.data)}',
      );
      return _mapResponse(response.data);
    } on DioException catch (error) {
      logger.warning(
        '[AUTH_REGISTER_STEP3] Passenger error: '
        'status=${error.response?.statusCode} '
        'data=${redactAuthLogData(error.response?.data)}',
      );
      ApiClient.handleDioError(error);
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
            "La validation de cette etape d'authentification a echoue.",
      );
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: "Impossible d'executer l'authentification passager : $error",
      );
    }
  }

  Map<String, dynamic> _mapResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    throw const ServerException(
      message: "Reponse serveur invalide pour l'authentification passager.",
    );
  }
}
