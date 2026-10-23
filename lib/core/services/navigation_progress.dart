/// Calculs du guidage pas à pas : où en est le chauffeur sur l'itinéraire.
library;

import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/directions_models.dart';

/// Écart (mètres) au-delà duquel le chauffeur est considéré hors itinéraire.
const double offRouteThresholdMeters = 60;

/// Distance (mètres) à la destination en dessous de laquelle on est arrivé.
const double arrivalThresholdMeters = 30;

const double _earthRadiusMeters = 6371000;

double distanceBetweenMeters(LatLng a, LatLng b) {
  final dLat = _rad(b.latitude - a.latitude);
  final dLng = _rad(b.longitude - a.longitude);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.latitude)) *
          math.cos(_rad(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.min(1, math.sqrt(h)));
}

/// Cap (0-360°) pour aller de [from] à [to].
double bearingBetween(LatLng from, LatLng to) {
  final lat1 = _rad(from.latitude);
  final lat2 = _rad(to.latitude);
  final dLng = _rad(to.longitude - from.longitude);
  final y = math.sin(dLng) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

double _rad(double degrees) => degrees * math.pi / 180;

class _Projection {
  const _Projection({
    required this.segment,
    required this.point,
    required this.distance,
  });

  final int segment;
  final LatLng point;
  final double distance;
}

/// Projection de [p] sur le segment le plus proche de [points] (repère plan local, suffisant sur quelques km).
_Projection? _project(LatLng p, List<LatLng> points) {
  if (points.isEmpty) return null;
  if (points.length == 1) {
    return _Projection(
      segment: 0,
      point: points.first,
      distance: distanceBetweenMeters(p, points.first),
    );
  }

  final cosLat = math.cos(_rad(p.latitude));
  double x(LatLng v) =>
      _rad(v.longitude - p.longitude) * cosLat * _earthRadiusMeters;
  double y(LatLng v) => _rad(v.latitude - p.latitude) * _earthRadiusMeters;

  _Projection? best;
  for (var i = 0; i < points.length - 1; i++) {
    final ax = x(points[i]);
    final ay = y(points[i]);
    final bx = x(points[i + 1]);
    final by = y(points[i + 1]);
    final dx = bx - ax;
    final dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;
    final t = lengthSquared == 0
        ? 0.0
        : (((-ax) * dx + (-ay) * dy) / lengthSquared).clamp(0.0, 1.0);
    final px = ax + t * dx;
    final py = ay + t * dy;
    final distance = math.sqrt(px * px + py * py);
    if (best == null || distance < best.distance) {
      best = _Projection(
        segment: i,
        point: LatLng(
          points[i].latitude +
              (points[i + 1].latitude - points[i].latitude) * t,
          points[i].longitude +
              (points[i + 1].longitude - points[i].longitude) * t,
        ),
        distance: distance,
      );
    }
  }
  return best;
}

/// Écart (mètres) entre [position] et le tracé [points].
double distanceToPolylineMeters(LatLng position, List<LatLng> points) =>
    _project(position, points)?.distance ?? double.infinity;

class NavigationProgress {
  const NavigationProgress({
    required this.stepIndex,
    required this.distanceToManeuverMeters,
    required this.remainingMeters,
    required this.remainingSeconds,
    required this.distanceFromRouteMeters,
    required this.isOffRoute,
    required this.hasArrived,
  });

  /// Manoeuvre en cours (indice dans `route.steps`).
  final int stepIndex;

  /// Distance restante jusqu'à la fin de la manoeuvre en cours, donc jusqu'à la prochaine consigne.
  final double distanceToManeuverMeters;
  final double remainingMeters;
  final double remainingSeconds;
  final double distanceFromRouteMeters;
  final bool isOffRoute;
  final bool hasArrived;

  /// Calcule la progression de [position] sur [route].
  ///
  /// [minStepIndex] empêche de « revenir en arrière » sur une manoeuvre déjà passée (boucles, demi-tours).
  /// Retourne null quand l'itinéraire n'a pas de manoeuvres.
  static NavigationProgress? compute(
    DirectionsRoute route,
    LatLng position, {
    int minStepIndex = 0,
    double offRouteThreshold = offRouteThresholdMeters,
  }) {
    final steps = route.steps;
    if (steps.isEmpty) return null;

    final stepPoints = [for (final step in steps) step.getPolylinePoints()];
    var bestIndex = minStepIndex.clamp(0, steps.length - 1);
    _Projection? bestProjection;
    for (var i = bestIndex; i < steps.length; i++) {
      final projection = _project(position, stepPoints[i]);
      if (projection == null) continue;
      if (bestProjection == null ||
          projection.distance < bestProjection.distance - 1) {
        bestProjection = projection;
        bestIndex = i;
      }
    }
    if (bestProjection == null) return null;

    final points = stepPoints[bestIndex];
    final nextVertex = math.min(bestProjection.segment + 1, points.length - 1);
    var toStepEnd = distanceBetweenMeters(
      bestProjection.point,
      points[nextVertex],
    );
    for (var i = bestProjection.segment + 1; i < points.length - 1; i++) {
      toStepEnd += distanceBetweenMeters(points[i], points[i + 1]);
    }

    final step = steps[bestIndex];
    final stepFraction = step.distanceMeters <= 0
        ? 0.0
        : (toStepEnd / step.distanceMeters).clamp(0.0, 1.0);
    var remainingMeters = toStepEnd;
    var remainingSeconds = step.durationSeconds * stepFraction;
    for (var i = bestIndex + 1; i < steps.length; i++) {
      remainingMeters += steps[i].distanceMeters;
      remainingSeconds += steps[i].durationSeconds;
    }

    final destination = steps.last.end;
    final isLast = bestIndex == steps.length - 1;
    return NavigationProgress(
      stepIndex: bestIndex,
      distanceToManeuverMeters: toStepEnd,
      remainingMeters: remainingMeters,
      remainingSeconds: remainingSeconds,
      distanceFromRouteMeters: bestProjection.distance,
      isOffRoute: bestProjection.distance > offRouteThreshold,
      hasArrived:
          isLast &&
          distanceBetweenMeters(position, destination) <=
              arrivalThresholdMeters,
    );
  }
}

/// « 350 m », « 1,2 km » : distance lisible, arrondie comme une application de guidage.
String formatNavigationDistance(double meters) {
  if (meters < 1000) {
    final rounded = meters < 100
        ? (meters / 10).round() * 10
        : (meters / 50).round() * 50;
    return '${math.max(rounded, 0)} m';
  }
  return '${(meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0).replaceAll('.', ',')} km';
}

String formatNavigationDuration(double seconds) {
  final minutes = (seconds / 60).ceil();
  if (minutes < 60) return '${math.max(minutes, 1)} min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours h' : '$hours h ${rest.toString().padLeft(2, '0')}';
}
