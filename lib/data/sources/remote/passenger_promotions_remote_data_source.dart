library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../sources/api_client.dart';

class PassengerPromotionsRemoteDataSource {
  PassengerPromotionsRemoteDataSource({Dio? dio})
    : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<Map<String, dynamic>> applyPromoCode({
    required String code,
    required int userId,
    required double initialPrice,
    int? courseId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'code': code,
        'userId': userId,
        'initialPrice': initialPrice,
      };
      if (courseId != null) {
        payload['courseId'] = courseId;
      }
      final response = await _dio.post('/promotions/apply', data: payload);
      return _extractResponseMap(response.data);
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible d\'appliquer le code promo: $error',
      );
    }
  }

  Map<String, dynamic> _extractResponseMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ServerException(
      message: 'Format de reponse promotion invalide.',
    );
  }
}
