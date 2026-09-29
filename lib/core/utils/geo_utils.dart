library;

import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

double geoDistanceMeters(LatLng a, LatLng b) {
  const earthRadius = 6371000.0;
  final dLat = _toRadians(b.latitude - a.latitude);
  final dLng = _toRadians(b.longitude - a.longitude);
  final sa = math.sin(dLat / 2);
  final sb = math.sin(dLng / 2);
  final h =
      sa * sa +
      math.cos(_toRadians(a.latitude)) *
          math.cos(_toRadians(b.latitude)) *
          sb *
          sb;
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return earthRadius * c;
}

double _toRadians(double degree) => degree * (math.pi / 180);
