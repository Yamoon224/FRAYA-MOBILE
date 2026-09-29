library;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';

Failure mapDriverRideException(Object error) {
  if (error is AuthException) {
    return AuthFailure(message: error.message);
  }
  if (error is NetworkException) {
    return NetworkFailure(message: error.message);
  }
  if (error is CacheException) {
    return CacheFailure(message: error.message);
  }
  if (error is ValidationException) {
    return ValidationFailure(message: error.message, fields: error.fields);
  }
  if (error is ServerException) {
    return ServerFailure(
      message: error.message,
      statusCode: error.statusCode,
    );
  }
  return ServerFailure(message: error.toString());
}
