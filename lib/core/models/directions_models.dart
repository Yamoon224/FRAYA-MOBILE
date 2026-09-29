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
          durationInTrafficValue:
              (json['durationInTrafficValue'] as num?)?.toInt(),
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
  });

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
      durationInTrafficValue:
          (leg?['duration_in_traffic']?['value'] as num?)?.toInt(),
      trafficSegments: const [],
      hasTrafficData: false,
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
