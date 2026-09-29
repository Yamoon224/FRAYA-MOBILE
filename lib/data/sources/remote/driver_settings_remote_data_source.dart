library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../sources/api_client.dart';

class DriverSettingsRemoteDataSource {
  DriverSettingsRemoteDataSource({Dio? dio})
    : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getOwnNotifications() async {
    try {
      final response = await _dio.get('/notifications/own');
      return _extractList(response.data);
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible de charger les notifications chauffeur: $error',
      );
    }
  }

  Future<void> markNotificationsAsRead({
    required List<int> notificationIds,
    bool read = true,
  }) async {
    try {
      await _dio.post(
        '/notifications/read',
        data: {'notificationIds': notificationIds, 'read': read},
      );
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message:
            'Impossible de mettre à jour les notifications chauffeur: $error',
      );
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/change-password',
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible de changer le mot de passe chauffeur: $error',
      );
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    var current = data;
    while (current is Map) {
      final next = current['data'] ?? current['result'] ?? current['items'];
      if (next == null || identical(current, next)) break;
      current = next;
    }
    if (current is List) {
      return current
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }
}
