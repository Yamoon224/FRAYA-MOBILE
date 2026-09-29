/// Failures métier pour le pattern Either (dartz).
///
/// Chaque [Failure] correspond à un type d'erreur que les use cases
/// peuvent retourner via `Either<Failure, T>`.
library;

import 'package:equatable/equatable.dart';

/// Classe de base pour toutes les Failures.
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Échec lié au serveur / API.
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({required super.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Échec lié au cache local.
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Échec lié à la connexion réseau.
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Pas de connexion internet'});
}

/// Échec lié à l'authentification.
class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

/// Échec lié à une validation de données (422).
class ValidationFailure extends Failure {
  final Map<String, String>? fields;

  const ValidationFailure({required super.message, this.fields});

  @override
  List<Object?> get props => [message, fields];
}

/// Échec lié à un conflit de course active (403 sur /rides/maps/request).
class ActiveRideConflictFailure extends Failure {
  const ActiveRideConflictFailure({
    super.message = 'Vous avez déjà une course en cours.',
  });
}
