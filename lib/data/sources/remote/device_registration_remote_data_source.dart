library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../domain/models/device_registration.dart';
import '../../sources/api_client.dart';

class DeviceRegistrationRemoteDataSource {
  DeviceRegistrationRemoteDataSource({Dio? dio}) : _dio = dio;

  final Dio? _dio;
  Dio get _client => _dio ?? ApiClient.instance.dio;

  Future<void> register(DeviceRegistration registration) async {
    // Temporairement désactivé : cet endpoint n'existe pas côté backend.
    // await _postDeviceMutation('/device/register', registration);
  }

  Future<void> deactivate(DeviceRegistration registration) async {
    // Temporairement désactivé avec la synchronisation device backend.
    // await _postDeviceMutation('/device/deactivate', registration);
  }

  // Conservé pour réactiver la synchronisation quand le backend sera prêt.
  // ignore: unused_element
  Future<void> _postDeviceMutation(
    String path,
    DeviceRegistration registration,
  ) async {
    try {
      final response = await _client.post(path, data: registration.toJson());
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
