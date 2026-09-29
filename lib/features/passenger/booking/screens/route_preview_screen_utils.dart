import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/home_navigation_notifier.dart';
import '../../../../core/models/places_models.dart';
import '../models/booking_flow_state.dart';
import '../providers/booking_route_refresh_provider.dart';

const kAbidjanDefaultLatLng = LatLng(5.3167, -4.0167);

void goHomeAndResetSearchState(
  BuildContext context, {
  required bool openDestinationSearch,
}) {
  HomeNavigationNotifier.instance.requestResetSearchState();
  if (openDestinationSearch) {
    HomeNavigationNotifier.instance.requestOpenDestinationSearchOnHome();
  }
  context.go(RoutePaths.passengerHome);
}

void handleRoutePreviewBackPressed(
  BuildContext context, {
  required BookingFlowState flowState,
}) {
  const driverActiveStates = {
    BookingFlowState.driverAssigned,
    BookingFlowState.arrived,
    BookingFlowState.inProgress,
    BookingFlowState.completed,
  };
  if (driverActiveStates.contains(flowState)) {
    goHomeAndResetSearchState(context, openDestinationSearch: false);
    return;
  }
  if (flowState == BookingFlowState.searching) {
    goHomeAndResetSearchState(context, openDestinationSearch: false);
    return;
  }
  goHomeAndResetSearchState(context, openDestinationSearch: true);
}

LatLng resolveInitialDestinationLatLng({
  required PlaceDetails? destination,
  required Position? position,
  LatLng fallback = kAbidjanDefaultLatLng,
}) {
  if (destination != null && destination.hasValidCoordinates) {
    return LatLng(destination.latitude, destination.longitude);
  }
  if (position != null) {
    return LatLng(position.latitude, position.longitude);
  }
  return fallback;
}

LatLng resolveInitialPickupLatLng({
  required PlaceDetails? pickup,
  required BookingOriginSnapshot? snapshot,
  required Position? position,
  LatLng fallback = kAbidjanDefaultLatLng,
}) {
  if (pickup != null && pickup.hasValidCoordinates) {
    return LatLng(pickup.latitude, pickup.longitude);
  }
  if (snapshot != null) {
    return LatLng(snapshot.latitude, snapshot.longitude);
  }
  if (position != null) {
    return LatLng(position.latitude, position.longitude);
  }
  return fallback;
}

void animateFitBounds(
  GoogleMapController? mapController, {
  required bool mounted,
  required LatLng origin,
  required LatLng destination,
}) {
  if (!mounted || mapController == null) return;
  final southWest = LatLng(
    origin.latitude < destination.latitude ? origin.latitude : destination.latitude,
    origin.longitude < destination.longitude
        ? origin.longitude
        : destination.longitude,
  );
  final northEast = LatLng(
    origin.latitude > destination.latitude ? origin.latitude : destination.latitude,
    origin.longitude > destination.longitude
        ? origin.longitude
        : destination.longitude,
  );
  final bounds = LatLngBounds(southwest: southWest, northeast: northEast);
  final latDiff = (origin.latitude - destination.latitude).abs();
  final lngDiff = (origin.longitude - destination.longitude).abs();
  try {
    if (latDiff < 0.001 && lngDiff < 0.001) {
      mapController.animateCamera(CameraUpdate.newLatLng(origin));
      return;
    }
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  } catch (error) {
    debugPrint('Silent map animation error: $error');
  }
}
