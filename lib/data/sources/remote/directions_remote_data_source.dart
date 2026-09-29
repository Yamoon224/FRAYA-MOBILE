import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/models/directions_models.dart';
import '../../../core/utils/logger.dart';

final _log = AppLogger.instance;

class DirectionsRemoteDataSource {
  DirectionsRemoteDataSource({Dio? googleDio})
    : _googleDio = googleDio ?? Dio();

  final Dio _googleDio;

  String get _apiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String language = 'fr',
    bool includeAlternativeRoutes = false,
  }) async {
    try {
      final response = await _googleDio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'key': _apiKey,
          'language': language,
          'mode': 'driving',
          'departure_time': 'now',
          'alternatives': includeAlternativeRoutes.toString(),
        },
      );

      if (response.statusCode != 200) return null;

      final data = response.data;
      if (data['status'] != 'OK') {
        _log.error('Directions API error: ${data['status']}');
        return null;
      }

      final result = DirectionsResult.fromGoogleApi(data);
      final trafficByRoute = await _fetchTrafficSegmentsFromRoutesApi(
        origin: origin,
        destination: destination,
        includeAlternativeRoutes: includeAlternativeRoutes,
      );
      final sourceRoutes = includeAlternativeRoutes
          ? result.routes
          : result.routes.take(1).toList();
      final routes = _attachTrafficSegments(sourceRoutes, trafficByRoute);
      return result.copyWith(routes: routes);
    } catch (error) {
      _log.error('Exception in directions data source: $error');
      throw ServerException(message: 'Impossible de calculer l itineraire.');
    }
  }

  List<DirectionsRoute> _attachTrafficSegments(
    List<DirectionsRoute> routes,
    List<List<TrafficSegment>>? trafficByRoute,
  ) {
    if (trafficByRoute == null) {
      return routes
          .map(
            (route) => route.copyWith(
              trafficSegments: const [],
              hasTrafficData: false,
            ),
          )
          .toList();
    }

    return [
      for (var i = 0; i < routes.length; i++)
        routes[i].copyWith(
          trafficSegments: i < trafficByRoute.length
              ? trafficByRoute[i]
              : const <TrafficSegment>[],
          hasTrafficData:
              i < trafficByRoute.length && trafficByRoute[i].isNotEmpty,
        ),
    ];
  }

  Future<List<List<TrafficSegment>>?> _fetchTrafficSegmentsFromRoutesApi({
    required LatLng origin,
    required LatLng destination,
    required bool includeAlternativeRoutes,
  }) async {
    if (_apiKey.isEmpty) return null;

    try {
      final response = await _googleDio.post(
        'https://routes.googleapis.com/directions/v2:computeRoutes',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask':
                'routes.duration,'
                'routes.distanceMeters,'
                'routes.polyline.encodedPolyline,'
                'routes.travelAdvisory.speedReadingIntervals',
          },
        ),
        data: {
          'origin': _locationPayload(origin),
          'destination': _locationPayload(destination),
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE_OPTIMAL',
          'computeAlternativeRoutes': includeAlternativeRoutes,
          'polylineQuality': 'HIGH_QUALITY',
          'extraComputations': ['TRAFFIC_ON_POLYLINE'],
        },
      );

      if (response.statusCode != 200) return null;

      final json = response.data as Map<String, dynamic>;
      final rawRoutes = json['routes'] as List<dynamic>? ?? const [];
      if (rawRoutes.isEmpty) return null;

      return [
        for (final rawRoute in rawRoutes)
          _trafficSegmentsFromRoute(Map<String, dynamic>.from(rawRoute as Map)),
      ];
    } catch (error) {
      _log.warning('Routes API traffic segments unavailable: $error');
      return null;
    }
  }

  Map<String, dynamic> _locationPayload(LatLng point) {
    return {
      'location': {
        'latLng': {'latitude': point.latitude, 'longitude': point.longitude},
      },
    };
  }

  List<TrafficSegment> _trafficSegmentsFromRoute(Map<String, dynamic> route) {
    final advisory = route['travelAdvisory'] as Map<String, dynamic>?;
    final intervals =
        advisory?['speedReadingIntervals'] as List<dynamic>? ?? const [];

    final segments = <TrafficSegment>[];
    for (final interval in intervals) {
      final segment = _trafficSegmentFromInterval(interval);
      if (segment != null) segments.add(segment);
    }
    return segments;
  }

  TrafficSegment? _trafficSegmentFromInterval(Object? interval) {
    if (interval is! Map) return null;
    final item = Map<String, dynamic>.from(interval);
    final start = (item['startPolylinePointIndex'] as num?)?.toInt() ?? 0;
    final end = (item['endPolylinePointIndex'] as num?)?.toInt() ?? start + 1;
    if (end <= start) return null;

    final speed = item['speed']?.toString() ?? '';
    return TrafficSegment(
      startIndex: start,
      endIndex: end,
      level: _mapSpeedToLevel(speed),
    );
  }

  TrafficLevel _mapSpeedToLevel(String speed) {
    switch (speed.toUpperCase()) {
      case 'TRAFFIC_JAM':
      case 'STOP_AND_GO':
        return TrafficLevel.jam;
      case 'SLOW':
        return TrafficLevel.slow;
      default:
        return TrafficLevel.normal;
    }
  }
}
