/// Modeles pour les donnees d'itineraire Google.
library;

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TrafficLevel { normal, slow, jam }

class TrafficSegment {
  const TrafficSegment({
    required this.startIndex,
    required this.endIndex,
    required this.level,
  });

  final int startIndex;
  final int endIndex;
  final TrafficLevel level;
}

class DirectionsResult {
  DirectionsResult({required this.routes});

  final List<DirectionsRoute> routes;

  factory DirectionsResult.fromGoogleApi(Map<String, dynamic> json) {
    final parsedRoutes = <DirectionsRoute>[];
    final sourceRoutes = json['routes'] as List<dynamic>? ?? const [];

    for (var i = 0; i < sourceRoutes.length; i++) {
      final routeJson = sourceRoutes[i] as Map<String, dynamic>;
      parsedRoutes.add(DirectionsRoute.fromGoogleApi(routeJson));
    }

    return DirectionsResult(routes: parsedRoutes);
  }

  factory DirectionsResult.fromBackendApi(Map<String, dynamic> json) {
    return DirectionsResult(
      routes: [
        DirectionsRoute(
          encodedPolyline: json['polyline']?.toString() ?? '',
          distanceText: json['distanceText']?.toString() ?? '',
          distanceValue: (json['distanceValue'] as num?)?.toInt() ?? 0,
          durationText: json['durationText']?.toString() ?? '',
          durationValue: (json['durationValue'] as num?)?.toInt() ?? 0,
          arrivalTime: json['arrivalTime']?.toString(),
          durationInTrafficValue: (json['durationInTrafficValue'] as num?)
              ?.toInt(),
          trafficSegments: const [],
          hasTrafficData: false,
        ),
      ],
    );
  }

  DirectionsRoute get mainRoute {
    if (routes.isEmpty) return DirectionsRoute.empty();
    return routes.first;
  }

  DirectionsResult copyWith({List<DirectionsRoute>? routes}) {
    return DirectionsResult(routes: routes ?? this.routes);
  }
}

/// Une manoeuvre du guidage pas à pas (une « step » de l'API Directions).
class NavigationStep {
  const NavigationStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuver,
    required this.start,
    required this.end,
    this.encodedPolyline = '',
  });

  /// Consigne en texte brut (le HTML de Google est retiré).
  final String instruction;
  final int distanceMeters;
  final int durationSeconds;

  /// Ex. « turn-left », « roundabout-right », « straight » ; vide pour le départ.
  final String maneuver;
  final LatLng start;
  final LatLng end;
  final String encodedPolyline;

  factory NavigationStep.fromGoogleApi(Map<String, dynamic> json) {
    LatLng location(dynamic raw) => LatLng(
      (raw?['lat'] as num?)?.toDouble() ?? 0,
      (raw?['lng'] as num?)?.toDouble() ?? 0,
    );

    return NavigationStep(
      instruction: stripHtmlInstruction(
        json['html_instructions']?.toString() ?? '',
      ),
      distanceMeters: (json['distance']?['value'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration']?['value'] as num?)?.toInt() ?? 0,
      maneuver: json['maneuver']?.toString() ?? '',
      start: location(json['start_location']),
      end: location(json['end_location']),
      encodedPolyline: json['polyline']?['points']?.toString() ?? '',
    );
  }

  /// Points de la manoeuvre ; à défaut de tracé, la ligne droite début → fin.
  List<LatLng> getPolylinePoints() {
    if (encodedPolyline.isEmpty) return [start, end];
    final decoded = PolylinePoints.decodePolyline(encodedPolyline);
    return decoded
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  /// Google renvoie du HTML (`<b>`, `<div style=…>` pour les compléments) : on garde le texte,
  /// avec un espace à la place des blocs pour ne pas coller deux phrases.
  static String stripHtmlInstruction(String html) {
    return html
        .replaceAll(RegExp(r'<(div|br|/div)[^>]*>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class DirectionsRoute {
  const DirectionsRoute({
    required this.encodedPolyline,
    required this.distanceText,
    required this.distanceValue,
    required this.durationText,
    required this.durationValue,
    required this.arrivalTime,
    required this.durationInTrafficValue,
    required this.trafficSegments,
    required this.hasTrafficData,
    this.steps = const [],
  });

  final List<NavigationStep> steps;
  final String encodedPolyline;
  final String distanceText;
  final int distanceValue;
  final String durationText;
  final int durationValue;
  final String? arrivalTime;
  final int? durationInTrafficValue;
  final List<TrafficSegment> trafficSegments;
  final bool hasTrafficData;

  factory DirectionsRoute.empty() {
    return const DirectionsRoute(
      encodedPolyline: '',
      distanceText: '',
      distanceValue: 0,
      durationText: '',
      durationValue: 0,
      arrivalTime: null,
      durationInTrafficValue: null,
      trafficSegments: [],
      hasTrafficData: false,
    );
  }

  factory DirectionsRoute.fromGoogleApi(Map<String, dynamic> routeJson) {
    final legs = routeJson['legs'] as List<dynamic>? ?? const [];
    final leg = legs.isNotEmpty ? legs.first as Map<String, dynamic> : null;

    return DirectionsRoute(
      encodedPolyline:
          routeJson['overview_polyline']?['points']?.toString() ?? '',
      distanceText: leg?['distance']?['text']?.toString() ?? '',
      distanceValue: (leg?['distance']?['value'] as num?)?.toInt() ?? 0,
      durationText: leg?['duration']?['text']?.toString() ?? '',
      durationValue: (leg?['duration']?['value'] as num?)?.toInt() ?? 0,
      arrivalTime: leg?['duration_in_traffic']?['text']?.toString(),
      durationInTrafficValue: (leg?['duration_in_traffic']?['value'] as num?)
          ?.toInt(),
      trafficSegments: const [],
      hasTrafficData: false,
      steps: [
        for (final step in leg?['steps'] as List<dynamic>? ?? const [])
          NavigationStep.fromGoogleApi(step as Map<String, dynamic>),
      ],
    );
  }

  DirectionsRoute copyWith({
    List<TrafficSegment>? trafficSegments,
    bool? hasTrafficData,
  }) {
    return DirectionsRoute(
      encodedPolyline: encodedPolyline,
      distanceText: distanceText,
      distanceValue: distanceValue,
      durationText: durationText,
      durationValue: durationValue,
      arrivalTime: arrivalTime,
      durationInTrafficValue: durationInTrafficValue,
      trafficSegments: trafficSegments ?? this.trafficSegments,
      hasTrafficData: hasTrafficData ?? this.hasTrafficData,
      steps: steps,
    );
  }
}

extension DirectionsRouteX on DirectionsRoute {
  double get distanceKm => distanceValue / 1000;

  int get durationMinutes => (durationValue / 60).ceil();

  int get effectiveDurationMinutes => durationInTrafficValue != null
      ? (durationInTrafficValue! / 60).ceil()
      : durationMinutes;

  List<LatLng> getPolylinePoints() {
    if (encodedPolyline.isEmpty) return [];
    final decoded = PolylinePoints.decodePolyline(encodedPolyline);
    return decoded
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }
}
