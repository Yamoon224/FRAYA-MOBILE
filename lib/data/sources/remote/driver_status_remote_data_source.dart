library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../sources/api_client.dart';

class DriverStatusRemoteDataSource {
  DriverStatusRemoteDataSource({Dio? dio})
    : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<void> updateStatus({required bool isOnline}) async {
    try {
      final response = await _dio.put(
        '/sid-users/me/online',
        data: {'isOnline': isOnline},
      );
      _ensureSuccess(response, 'statut chauffeur');
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: 'Impossible de mettre à jour le statut chauffeur : $error',
      );
    }
  }

  Future<void> sendHeartbeat() async {
    try {
      final response = await _dio.post('/sid-users/me/heartbeat');
      _ensureSuccess(response, 'heartbeat chauffeur');
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(
        message: 'Impossible d\'envoyer le heartbeat chauffeur : $error',
      );
    }
  }

  void _ensureSuccess(Response<dynamic> response, String operation) {
    final statusCode = response.statusCode;
    if (statusCode != null && statusCode >= 200 && statusCode < 300) return;
    throw ServerException(
      message: 'Reponse serveur inattendue pour le $operation.',
      statusCode: statusCode,
    );
  }
}
