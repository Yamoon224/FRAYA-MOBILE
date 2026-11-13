library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../domain/models/device_registration.dart';
import '../../sources/api_client.dart';

class DeviceRegistrationRemoteDataSource {
  DeviceRegistrationRemoteDataSource({Dio? dio}) : _dio = dio;

  final Dio? _dio;
  Dio get _client => _dio ?? ApiClient.instance.dio;

  /// Associe le jeton FCM de l'appareil à l'utilisateur connecté.
  Future<void> register(DeviceRegistration registration) {
    return _postDeviceMutation(
      '/devices/register',
      registration.toRegisterRequest(),
    );
  }

  /// Retire le jeton FCM : l'appareil ne reçoit plus de notifications pour cet utilisateur.
  Future<void> deactivate(DeviceRegistration registration) {
    return _postDeviceMutation(
      '/devices/deactivate',
      registration.toDeactivateRequest(),
    );
  }

  Future<void> _postDeviceMutation(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.post(path, data: body);
      if (_isSuccess(response.statusCode)) {
        return;
      }
      throw ServerException(
        message: 'Reponse serveur inattendue pour le device.',
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: 'Impossible de synchroniser le device : $error',
      );
    }
  }

  bool _isSuccess(int? statusCode) {
    return statusCode == 200 || statusCode == 201 || statusCode == 204;
  }
}
