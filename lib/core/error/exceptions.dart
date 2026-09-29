/// Exceptions métier de l'application.
///
/// Ces exceptions sont lancées dans la couche Data et interceptées
/// dans la couche Domain pour être transformées en [Failure].
library;

/// Exception levée quand le serveur retourne une erreur.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Exception levée quand le cache local échoue.
class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

/// Exception levée quand il n'y a pas de connexion réseau.
class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'Pas de connexion internet'});

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception levée lors d'un problème d'authentification.
class AuthException implements Exception {
  final String message;

  const AuthException({required this.message});

  @override
  String toString() => 'AuthException: $message';
}

/// Exception levée quand le serveur retourne une erreur de validation (422).
class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fields;

  const ValidationException({required this.message, this.fields});

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception levée lorsqu'un document local ne peut pas être préparé.
class DocumentPreparationException implements Exception {
  final String message;

  const DocumentPreparationException({required this.message});

  @override
  String toString() => 'DocumentPreparationException: $message';
}

/// Exception levée quand l'utilisateur tente de créer une course alors qu'il en a déjà une active (403).
class ActiveRideConflictException implements Exception {
  final String message;

  const ActiveRideConflictException({
    this.message = 'Vous avez déjà une course en cours.',
  });

  @override
  String toString() => 'ActiveRideConflictException: $message';
}
