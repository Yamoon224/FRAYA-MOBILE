library;

import 'package:dio/dio.dart';

import '../../core/error/exceptions.dart';
import '../../core/services/api_availability_guard.dart';

class ApiAvailabilityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_shouldBlock(options)) {
      handler.next(options);
      return;
    }

    options.extra['availabilityBlocked'] = true;
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: const NetworkException(
          message:
              'Connexion au serveur indisponible. Réessayez dans un instant.',
        ),
        message: 'Connexion au serveur indisponible.',
      ),
    );
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    ApiAvailabilityGuard.instance.recordReachable();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _syncAvailabilityFromError(err);
    handler.next(err);
  }

  bool _shouldBlock(RequestOptions options) {
    if (options.extra['skipAvailabilityGuard'] == true) return false;
    return ApiAvailabilityGuard.instance.shouldBlockMethod(options.method);
  }

  void _syncAvailabilityFromError(DioException error) {
    if (error.requestOptions.extra['availabilityBlocked'] == true) return;
    if (error.response != null) {
      ApiAvailabilityGuard.instance.recordReachable();
      return;
    }
    if (_isConnectivityError(error)) {
      ApiAvailabilityGuard.instance.recordConnectivityFailure();
    }
  }

  bool _isConnectivityError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }
}
