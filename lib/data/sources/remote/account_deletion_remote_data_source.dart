library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../sources/api_client.dart';

class AccountDeletionRemoteDataSource {
  AccountDeletionRemoteDataSource({Dio? dio})
    : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<void> deleteAccount(int userId) async {
    try {
      final response = await _dio.delete('/sid-users/delete/$userId');
      // Le serveur répond parfois 200 avec { success: false, message } (par exemple : course en cours).
      final data = response.data;
      if (data is Map && data['success'] == false) {
        throw ServerException(
          message: data['message']?.toString() ?? 'Impossible de supprimer le compte.',
          statusCode: (data['statusCode'] as num?)?.toInt(),
        );
      }
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException(
        message: 'Impossible de supprimer le compte : $error',
      );
    }
  }
}
