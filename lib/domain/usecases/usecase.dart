/// Contrat de base pour tous les use cases.
///
/// Suit le pattern Clean Architecture :
/// ```dart
/// class GetUserProfile extends UseCase<UserEntity, String> {
///   @override
///   Future<Either<Failure, UserEntity>> call(String userId) async { ... }
/// }
/// ```
library;

import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';

/// Use case avec paramètres.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use case sans paramètres.
abstract class UseCaseNoParams<T> {
  Future<Either<Failure, T>> call();
}

/// Paramètre vide (pour les use cases qui n'ont pas besoin de params).
class NoParams {
  const NoParams();
}
