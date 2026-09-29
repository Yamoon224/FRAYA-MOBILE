import 'dart:ui' show Offset;

import 'package:google_maps_flutter/google_maps_flutter.dart';

void addRouteAddressMarkers({
  required Set<Marker> markers,
  required LatLng? origin,
  required LatLng? destination,
  required BitmapDescriptor? pickupIcon,
  required BitmapDescriptor? destinationIcon,
  void Function(LatLng)? onPickupTap,
  void Function(LatLng)? onDestinationTap,
}) {
  if (origin != null) {
    markers.add(
      Marker(
        markerId: const MarkerId('origin'),
        position: origin,
        icon:
            pickupIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 1),
        onTap: onPickupTap == null ? null : () => onPickupTap(origin),
      ),
    );
  }

  if (destination != null) {
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon:
            destinationIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 1),
        onTap: onDestinationTap == null
            ? null
            : () => onDestinationTap(destination),
      ),
    );
  }
}
