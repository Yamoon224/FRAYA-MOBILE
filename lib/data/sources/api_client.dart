/// Client HTTP Dio configuré pour l'API Fraya.
///
/// Inclut les intercepteurs :
/// - Auth (injection automatique du Bearer token)
/// - Logging (en mode dev uniquement)
/// - Error handling (transformation en exceptions métier)
library;

import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/error/exceptions.dart';
import '../../core/services/auth_session_notifier.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/logger.dart';
import 'api_availability_interceptor.dart';
import 'local_storage.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  late Dio _dio;
  final LocalStorage _storage = LocalStorage.instance;
  bool _isRefreshing = false;
  Completer<_RefreshTokenResult>? _refreshCompleter;

  Dio get dio => _dio;

  /// Initialise le client Dio avec la config active.
  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.instance.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(ApiAvailabilityInterceptor());

    // Intercepteur Auth — injecte le token dans chaque requête
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final tokenKey = AppConfig.instance.isDriver
              ? AppConstants.driverAccessTokenKey
              : AppConstants.accessTokenKey;
          final token = await _storage.getSecure(tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            final path = error.requestOptions.path.toLowerCase();
            final hasAuthHeader =
                error.requestOptions.headers['Authorization'] != null;
            final isAuthEndpoint =
                path.contains('/auth/login') ||
                path.contains('/auth/register') ||
                path.contains('/auth/refresh-token');
            final isRetry = error.requestOptions.extra['retried'] == true;

            if (hasAuthHeader && !isAuthEndpoint) {
              if (!isRetry) {
                final refreshResult = await _tryRefreshToken();
                if (refreshResult == _RefreshTokenResult.success) {
                  final tokenKey = AppConfig.instance.isDriver
                      ? AppConstants.driverAccessTokenKey
                      : AppConstants.accessTokenKey;
                  final newToken = await _storage.getSecure(tokenKey);
                  final opts = error.requestOptions
                    ..headers['Authorization'] = 'Bearer $newToken'
                    ..extra['retried'] = true;
                  try {
                    final response = await _dio.fetch(opts);
                    handler.resolve(response);
                    return;
                  } catch (_) {}
                }
                if (refreshResult == _RefreshTokenResult.networkFailure) {
                  logger.warning(
                    'Refresh token interrompu par le reseau: $path',
                  );
                  handler.next(error);
                  return;
                }
              }
              AuthSessionNotifier.instance.notifyExpired(
                'Votre session a expiré. Veuillez vous reconnecter.',
              );
              logger.warning('Session expirée — refresh échoué.');
            }
          }
          handler.next(error);
        },
      ),
    );

    // Intercepteur Logging — dev uniquement
    if (AppConfig.instance.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => logger.debug(obj),
        ),
      );
    }
  }

  Future<_RefreshTokenResult> _tryRefreshToken() async {
    if (_isRefreshing) return _refreshCompleter!.future;

    _isRefreshing = true;
    _refreshCompleter = Completer<_RefreshTokenResult>();
    var result = _RefreshTokenResult.failed;
    try {
      final refreshToken = await _storage.getSecure(
        AppConstants.refreshTokenKey,
      );
      if (refreshToken == null) {
        result = _RefreshTokenResult.missingToken;
        logger.warning('Refresh token absent du stockage sécurisé');
        return result;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConfig.instance.baseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      );
      refreshDio.httpClientAdapter = _dio.httpClientAdapter;
      final response = await refreshDio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      final newToken = data is Map
          ? (data['data']?['access_token'] ??
                data['data']?['accessToken'] ??
                data['access_token'] ??
                data['accessToken'])
          : null;
      final newRefreshToken = data is Map
          ? (data['data']?['refresh_token'] ??
                data['data']?['refreshToken'] ??
                data['refresh_token'] ??
                data['refreshToken'])
          : null;

      if (newToken != null) {
        final tokenKey = AppConfig.instance.isDriver
            ? AppConstants.driverAccessTokenKey
            : AppConstants.accessTokenKey;
        await _storage.setSecure(tokenKey, newToken.toString());
        // Le backend fait tourner le refresh token : persister le nouveau,
        // sinon le prochain refresh présentera un token déjà invalidé.
        if (newRefreshToken != null) {
          await _storage.setSecure(
            AppConstants.refreshTokenKey,
            newRefreshToken.toString(),
          );
        }
        AuthSessionNotifier.instance.notifyTokenRefreshed();
        result = _RefreshTokenResult.success;
      }
    } on DioException catch (error) {
      result = _mapRefreshError(error);
      logger.warning(
        'Refresh token ${AppConfig.instance.flavor}: $result',
        error,
        error.stackTrace,
      );
    } catch (error, stackTrace) {
      result = _RefreshTokenResult.failed;
      logger.warning('Refresh token impossible', error, stackTrace);
    } finally {
      _isRefreshing = false;
      _refreshCompleter!.complete(result);
      _refreshCompleter = null;
    }
    return result;
  }

  _RefreshTokenResult _mapRefreshError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return _RefreshTokenResult.networkFailure;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return _RefreshTokenResult.authRejected;
        }
        return _RefreshTokenResult.failed;
      default:
        return _RefreshTokenResult.failed;
    }
  }

  /// Transforme une [DioException] en exception métier.
  static Never handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const NetworkException(
          message: 'La connexion a expiré. Réessayez.',
        );
      case DioExceptionType.connectionError:
        if (e.error is NetworkException) {
          throw e.error as NetworkException;
        }
        throw const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = _extractErrorMessage(e.response);
        final validationFields = _extractValidationFields(e.response);
        if (statusCode == 403) {
          final path = e.requestOptions.path.toLowerCase();
          if (path.contains('/rides/maps/request')) {
            // Seul ce endpoint mappe 403 vers un conflit de course active.
            throw ActiveRideConflictException(message: message);
          }
          // Tous les autres 403 restent des erreurs d'authentification.
          throw AuthException(message: message);
        }
        if (statusCode == 401) {
          throw AuthException(message: message);
        }
        if ((statusCode == 400 || statusCode == 422) &&
            _isValidationResponse(message: message, fields: validationFields)) {
          throw ValidationException(message: message, fields: validationFields);
        }
        throw ServerException(message: message, statusCode: statusCode);
      default:
        logger.error(
          'Dio Error Non Gérée: Type=${e.type}, Error=${e.error}, Msg=${e.message}',
        );
        throw ServerException(
          message: e.message ?? 'Erreur de connexion au serveur',
        );
    }
  }

  static String _extractErrorMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        final detailedError = _extractDetailedError(data['errors']);
        if (message is String && message.trim().isNotEmpty) {
          if (_isGenericValidationMessage(message)) {
            if (detailedError != null) return detailedError;
            final error = data['error'];
            if (error is String && error.trim().isNotEmpty) return error;
          }
          return message;
        }
        if (message is List && message.isNotEmpty) {
          return message.first.toString();
        }
        if (detailedError != null) return detailedError;

        final error = data['error'];
        if (error is String) return error;
      }
    } catch (_) {}
    return 'Erreur serveur (${response?.statusCode})';
  }

  static Map<String, String>? _extractValidationFields(Response? response) {
    try {
      final data = response?.data;
      if (data is! Map<String, dynamic>) return null;

      final errors = data['errors'];
      if (errors is Map) {
        return errors.map(
          (key, value) => MapEntry(key.toString(), _normalizeFieldValue(value)),
        );
      }
      if (errors is List) {
        final fields = <String, String>{};
        for (final e in errors) {
          if (e is Map && e.containsKey('field')) {
            fields[e['field'].toString()] = _normalizeFieldValue(e['message']);
          }
        }
        return fields.isNotEmpty ? fields : null;
      }
    } catch (_) {}
    return null;
  }

  static bool _isValidationResponse({
    required String message,
    required Map<String, String>? fields,
  }) {
    return (fields != null && fields.isNotEmpty) ||
        _isGenericValidationMessage(message);
  }

  static bool _isGenericValidationMessage(String message) {
    final normalized = message.trim().toLowerCase();
    return normalized == 'validation failed' ||
        normalized == 'validation error' ||
        normalized == 'bad request';
  }

  static String? _extractDetailedError(dynamic errors) {
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map) {
        final message = first['message'];
        if (message != null) return _normalizeFieldValue(message);
        if (first.isNotEmpty) {
          return _normalizeFieldValue(first.values.first);
        }
      }
      return _normalizeFieldValue(first);
    }
    if (errors is Map && errors.isNotEmpty) {
      return _normalizeFieldValue(errors.values.first);
    }
    return null;
  }

  static String _normalizeFieldValue(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    return value?.toString() ?? '';
  }
}

enum _RefreshTokenResult {
  success,
  missingToken,
  authRejected,
  networkFailure,
  failed,
}
