/// Service dedicated to Google Directions API calls.
library;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/directions_models.dart';
import '../utils/logger.dart';

final _log = AppLogger.instance;

class DirectionsService {
  DirectionsService({Dio? googleDio}) : _googleDio = googleDio ?? Dio();

  final Dio _googleDio;

  String get _apiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String language = 'fr',
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
          'alternatives': 'true',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = response.data;
      if (data['status'] != 'OK') {
        _log.error('Directions API error: ${data['status']}');
        return null;
      }

      final result = DirectionsResult.fromGoogleApi(data);
      final trafficByRoute = await _fetchTrafficSegmentsFromRoutesApi(
        origin: origin,
        destination: destination,
      );

      final routes = _attachTrafficSegments(result.routes, trafficByRoute);
      return result.copyWith(routes: routes);
    } catch (error) {
      _log.error('Exception in getDirections: $error');
      return null;
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

    final updated = <DirectionsRoute>[];
    for (var i = 0; i < routes.length; i++) {
      final segments = i < trafficByRoute.length
          ? trafficByRoute[i]
          : const <TrafficSegment>[];
      updated.add(
        routes[i].copyWith(
          trafficSegments: segments,
          hasTrafficData: segments.isNotEmpty,
        ),
      );
    }
    return updated;
  }

  Future<List<List<TrafficSegment>>?> _fetchTrafficSegmentsFromRoutesApi({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (_apiKey.isEmpty) return null;

    try {
      // final response = await _googleDio.post(
      //   'https://routes.googleapis.com/directions/v2:computeRoutes',
      //   options: Options(
      //     headers: {
      //       'Content-Type': 'application/json',
      //       'X-Goog-Api-Key': _apiKey,
      //       'X-Goog-FieldMask':
      //           'routes.travelAdvisory.speedReadingIntervals,routes.polyline.encodedPolyline',
      //     },
      //   ),
      //   data: {
      //     'origin': {
      //       'location': {
      //         'latLng': {
      //           'latitude': origin.latitude,
      //           'longitude': origin.longitude,
      //         },
      //       },
      //     },
      //     'destination': {
      //       'location': {
      //         'latLng': {
      //           'latitude': destination.latitude,
      //           'longitude': destination.longitude,
      //         },
      //       },
      //     },
      //     'travelMode': 'DRIVE',
      //     'routingPreference': 'TRAFFIC_AWARE',
      //     'computeAlternativeRoutes': true,
      //     'polylineQuality': 'OVERVIEW',
      //   },
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
          'origin': {
            'location': {
              'latLng': {
                'latitude': origin.latitude,
                'longitude': origin.longitude,
              },
            },
          },

          'destination': {
            'location': {
              'latLng': {
                'latitude': destination.latitude,
                'longitude': destination.longitude,
              },
            },
          },
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE_OPTIMAL',
          'computeAlternativeRoutes': true,
          'polylineQuality': 'HIGH_QUALITY',
          'extraComputations': ['TRAFFIC_ON_POLYLINE'],
        },
      );

      if (response.statusCode != 200) return null;

      final json = response.data as Map<String, dynamic>;
      final rawRoutes = json['routes'] as List<dynamic>? ?? const [];
      if (rawRoutes.isEmpty) return null;

      final allSegments = <List<TrafficSegment>>[];
      for (final rawRoute in rawRoutes) {
        final routeMap = rawRoute as Map<String, dynamic>;
        final advisory = routeMap['travelAdvisory'] as Map<String, dynamic>?;
        final intervals =
            advisory?['speedReadingIntervals'] as List<dynamic>? ?? const [];

        final segments = <TrafficSegment>[];
        for (final interval in intervals) {
          final item = interval as Map<String, dynamic>;
          final start = (item['startPolylinePointIndex'] as num?)?.toInt() ?? 0;
          final end =
              (item['endPolylinePointIndex'] as num?)?.toInt() ?? start + 1;
          if (end <= start) continue;

          final speed = item['speed']?.toString() ?? '';
          segments.add(
            TrafficSegment(
              startIndex: start,
              endIndex: end,
              level: _mapSpeedToLevel(speed),
            ),
          );
        }

        allSegments.add(segments);
      }

      return allSegments;
    } catch (error) {
      _log.warning('Routes API traffic segments unavailable: $error');
      return null;
    }
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
