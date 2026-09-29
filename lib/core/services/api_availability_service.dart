library;

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_availability_guard.dart';

class ApiAvailabilityService {
  ApiAvailabilityService({
    Dio? dio,
    String? baseUrl,
    Duration timeout = const Duration(seconds: 3),
  }) : _dio = dio ?? Dio(),
       _baseUrl = baseUrl ?? AppConfig.instance.baseUrl,
       _timeout = timeout;

  final Dio _dio;
  final String _baseUrl;
  final Duration _timeout;

  Future<ApiAvailabilityState> check() async {
    if (await _probe('HEAD')) return ApiAvailabilityState.reachable;
    if (await _probe('GET')) return ApiAvailabilityState.reachable;
    return ApiAvailabilityState.unreachable;
  }

  Future<bool> _probe(String method) async {
    try {
      final response = await _dio.requestUri<void>(
        Uri.parse(_baseUrl),
        options: Options(
          method: method,
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
          validateStatus: (_) => true,
        ),
      );
      return response.statusCode != null;
    } on DioException catch (error) {
      return !_isConnectivityFailure(error);
    } catch (_) {
      return true;
    }
  }

  bool _isConnectivityFailure(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }
}
