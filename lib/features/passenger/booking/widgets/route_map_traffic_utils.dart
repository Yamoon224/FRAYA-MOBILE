import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/models/directions_models.dart';

Set<Polyline> buildTrafficPolylines({
  required DirectionsRoute route,
  required int routeIndex,
}) {
  final points = route.getPolylinePoints();
  final polylines = <Polyline>{};
  final maxIndex = points.length - 1;

  for (var i = 0; i < route.trafficSegments.length; i++) {
    final segment = route.trafficSegments[i];
    final start = segment.startIndex.clamp(0, maxIndex).toInt();
    final end = segment.endIndex.clamp(start + 1, points.length).toInt();
    if (end - start < 2) continue;

    polylines.add(
      Polyline(
        polylineId: PolylineId('traffic_${routeIndex}_$i'),
        points: points.sublist(start, end),
        width: 6,
        zIndex: 2,
        color: trafficColor(segment.level),
      ),
    );
  }

  return polylines;
}

Color trafficColor(TrafficLevel level) {
  switch (level) {
    case TrafficLevel.jam:
      return const Color(0xFFD32F2F);
    case TrafficLevel.slow:
      return const Color(0xFFFF9800);
    case TrafficLevel.normal:
      return const Color(0xFF2E7D32);
  }
}
