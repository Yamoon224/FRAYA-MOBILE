import 'dart:ui' show Offset;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../domain/models/active_ride.dart';
import '../../map/providers/nearby_drivers_provider.dart';
import '../models/booking_flow_state.dart';
import 'route_map_marker_policy.dart';

Set<Marker> buildRouteMapDriverMarkers({
  required BookingFlowState flowState,
  required ActiveRide? ride,
  required List<NearbyDriver> nearbyDrivers,
  required BitmapDescriptor defaultDriverCarIcon,
  required Map<String, BitmapDescriptor> nearbyDriverIcons,
  BitmapDescriptor? activeRideDriverIcon,
  LatLng? overrideDriverPosition,
  double overrideDriverBearing = 0,
}) {
  final mode = resolveDriverLayerMode(
    flowState: flowState,
    hasActiveRide: ride != null,
  );

  if (mode == RouteMapDriverLayerMode.activeRideOnly && ride != null) {
    return {
      Marker(
        markerId: const MarkerId('driver'),
        position: overrideDriverPosition ?? ride.driverLocation,
        rotation: overrideDriverBearing,
        icon: activeRideDriverIcon ?? defaultDriverCarIcon,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(title: ride.driverName),
      ),
    };
  }

  return {
    for (final driver in nearbyDrivers)
      Marker(
        markerId: MarkerId(driver.id),
        position: driver.location,
        icon: nearbyDriverIcons[driver.id] ?? defaultDriverCarIcon,
        rotation: driver.bearing,
        flat: true,
        anchor: const Offset(0.5, 0.5),
      ),
  };
}
