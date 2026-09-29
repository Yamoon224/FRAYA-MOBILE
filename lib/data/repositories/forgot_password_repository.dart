library;

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/error/exceptions.dart';
import '../../core/utils/auth_step_response_validator.dart';
import '../../core/utils/extensions.dart';
import '../../data/sources/api_client.dart';

class ForgotPasswordRepository {
  ForgotPasswordRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  Future<void> sendResetCode(String identifier) async {
    final trimmedIdentifier = identifier.trim();
    final body = trimmedIdentifier.isValidEmail
        ? {'email': trimmedIdentifier, 'type': _userType}
        : {'phoneNumber': trimmedIdentifier, 'type': _userType};
    try {
      final response = await _dio.post('/auth/forgot-password', data: body);
      ensureAuthStepSucceeded(
        response.data,
        fallbackMessage: 'Impossible d\'envoyer le code.',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Impossible d\'envoyer le code : $e');
    }
  }

  Future<void> resetPassword(
    String verificationCode,
    String newPassword,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/reset-mobile-password',
        data: {
          'verificationCode': verificationCode,
          'newPassword': newPassword,
        },
      );
      ensureAuthStepSucceeded(
        response.data,
        fallbackMessage: 'Impossible de réinitialiser le mot de passe.',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Impossible de réinitialiser le mot de passe : $e',
      );
    }
  }

  String get _userType => AppConfig.instance.isDriver ? 'DRIVER' : 'CLIENT';
}
