import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/providers/places_provider.dart';
import '../../map/providers/nearby_drivers_provider.dart';
import 'active_ride_live_metrics_provider.dart';
import 'booking_route_refresh_provider.dart';

part 'nearest_driver_eta_provider.g.dart';

@riverpod
int? nearestDriverEtaMinutes(Ref ref) {
  final origin = _resolveOrigin(ref);
  if (origin == null) return null;

  final nearbyDrivers = ref.watch(nearbyDriversProvider);
  if (nearbyDrivers.isEmpty) return null;

  final averageSpeedKmh = ref.watch(
    activeRideLiveMetricsAverageSpeedKmhProvider,
  );
  if (averageSpeedKmh <= 0) return null;

  double? nearestMeters;
  for (final driver in nearbyDrivers) {
    final meters = ActiveRideLiveMetricsCalculator.distanceMeters(
      driver.location,
      origin,
    );
    if (nearestMeters == null || meters < nearestMeters) {
      nearestMeters = meters;
    }
  }

  if (nearestMeters == null) return null;
  return math.max(1, ((nearestMeters / 1000) / averageSpeedKmh * 60).ceil());
}

LatLng? _resolveOrigin(Ref ref) {
  final pickup = ref.watch(selectedPickupProvider);
  if (pickup != null && pickup.hasValidCoordinates) {
    return LatLng(pickup.latitude, pickup.longitude);
  }

  final snapshot = ref.watch(bookingOriginSnapshotProvider);
  if (snapshot != null) {
    return LatLng(snapshot.latitude, snapshot.longitude);
  }

  final position = ref.watch(currentLocationProvider).asData?.value;
  if (position != null) {
    return LatLng(position.latitude, position.longitude);
  }

  return null;
}
