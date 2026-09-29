library;

import 'exceptions.dart';
import 'failures.dart';

Failure mapAppException(Object error) {
  if (error is AuthException) {
    return AuthFailure(message: error.message);
  }
  if (error is NetworkException) {
    return NetworkFailure(message: error.message);
  }
  if (error is ValidationException) {
    return ValidationFailure(message: error.message, fields: error.fields);
  }
  if (error is ServerException) {
    return ServerFailure(message: error.message, statusCode: error.statusCode);
  }
  if (error is CacheException) {
    return CacheFailure(message: error.message);
  }
  return ServerFailure(message: error.toString());
}
