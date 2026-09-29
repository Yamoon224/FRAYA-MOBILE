library;

import '../../../core/error/exceptions.dart';

/// Utilitaires de parsing des réponses API de réservation.
///
/// Centralise l'extraction des données depuis les réponses brutes
/// du backend (unwrap, liste de courses, course active, etc.).
class BookingResponseParser {
  const BookingResponseParser._();

  /// Convertit une réponse brute en Map typée.
  static Map<String, dynamic> asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ServerException(message: 'Unexpected API response format.');
  }

  /// Extrait une liste de courses depuis une réponse API.
  static List<Map<String, dynamic>> extractRideList(dynamic data) {
    final unwrapped = unwrapData(data);

    if (unwrapped is List) {
      return unwrapped
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (unwrapped is Map) {
      final map = Map<String, dynamic>.from(unwrapped);
      for (final key in ['data', 'rides', 'courses', 'items', 'results']) {
        final value = map[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
      return [map];
    }

    return const [];
  }

  /// Extrait une course unique (active) depuis une réponse API.
  static Map<String, dynamic>? extractRideMap(dynamic data) {
    final unwrapped = unwrapData(data);
    if (unwrapped is List) return _extractActiveFromList(unwrapped);
    if (unwrapped is Map && unwrapped.isNotEmpty) {
      final map = Map<String, dynamic>.from(unwrapped);
      final id = (map['id'] ??
              map['rideId'] ??
              map['courseId'] ??
              map['sidRace'] ??
              '')
          .toString();
      if (id.isEmpty) return null;
      return map;
    }
    return null;
  }

  /// Vérifie si une course est encore active (non terminée/annulée).
  static bool isActiveRide(Map<String, dynamic> ride) {
    final status = (ride['statusRace'] ??
            ride['status'] ??
            ride['rideStatus'] ??
            ride['courseStatus'] ??
            '')
        .toString()
        .toUpperCase();
    return status != 'COMPLETED' &&
        status != 'FINISHED' &&
        status != 'CANCELLED' &&
        status != 'CANCELED';
  }

  /// Déballe récursivement les enveloppes `data`/`result`.
  static dynamic unwrapData(dynamic data) {
    var current = data;
    while (current is Map &&
        (current.containsKey('data') || current.containsKey('result'))) {
      final next = current['data'] ?? current['result'];
      if (next == null || identical(next, current)) break;
      current = next;
    }
    return current;
  }

  static Map<String, dynamic>? _extractActiveFromList(List<dynamic> rides) {
    final parsed = rides
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    for (final ride in parsed) {
      if (isActiveRide(ride)) return ride;
    }
    return null;
  }
}
