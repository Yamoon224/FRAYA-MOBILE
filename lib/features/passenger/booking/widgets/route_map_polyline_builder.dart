import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/models/directions_models.dart';
import 'route_map_traffic_utils.dart';

Set<Polyline> buildPrimaryRoutePolylines(DirectionsRoute route) {
  final polylineCoords = route.getPolylinePoints();
  if (polylineCoords.isEmpty) return const {};

  if (route.hasTrafficData && route.trafficSegments.isNotEmpty) {
    return {
      Polyline(
        polylineId: const PolylineId('route_base_0'),
        points: polylineCoords,
        color: const Color(0xFF2E7D32),
        width: 6,
        zIndex: 1,
      ),
      ...buildTrafficPolylines(route: route, routeIndex: 0),
    };
  }

  return {
    Polyline(
      polylineId: const PolylineId('route_0'),
      points: polylineCoords,
      color: const Color(0xFF4285F4),
      width: 6,
      zIndex: 1,
    ),
  };
}
