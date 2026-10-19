library;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const Color driverRouteColor = Color(0xFF0B57D0);
const Color driverRouteOutlineColor = Colors.white;

/// Tracé de l'itinéraire du chauffeur : trait bleu avec un contour blanc dessous, extrémités et
/// jonctions arrondies, pour rester lisible sur tous les fonds de carte.
Set<Polyline> buildDriverRoutePolylines(List<LatLng> points) {
  if (points.isEmpty) return const <Polyline>{};
  return {
    Polyline(
      polylineId: const PolylineId('driver_active_ride_polyline_outline'),
      points: points,
      color: driverRouteOutlineColor,
      width: 12,
      geodesic: true,
      zIndex: 1,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    ),
    Polyline(
      polylineId: const PolylineId('driver_active_ride_polyline'),
      points: points,
      color: driverRouteColor,
      width: 8,
      geodesic: true,
      zIndex: 2,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    ),
  };
}
