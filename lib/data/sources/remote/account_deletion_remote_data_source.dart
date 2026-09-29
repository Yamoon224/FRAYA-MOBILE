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
      await _dio.delete('/sid-users/delete/$userId');
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
