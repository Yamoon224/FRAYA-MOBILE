import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/models/directions_models.dart';
import '../../../../core/models/places_models.dart';
import '../../../../domain/models/active_ride.dart';
import '../models/booking_flow_state.dart';
import '../providers/active_ride_map_route_provider.dart';
import '../providers/booking_route_refresh_provider.dart';

class RouteViewportTarget {
  const RouteViewportTarget({
    required this.contextKey,
    required this.origin,
    required this.destination,
  });

  final String contextKey;
  final LatLng origin;
  final LatLng destination;
}

class RouteViewportController {
  RouteViewportTarget? _currentTarget;
  String? _lastViewportContextKey;
  bool _hasUserAdjustedCamera = false;
  bool _isProgrammaticCameraMove = false;
  bool _hasPendingAutoFit = false;

  RouteViewportTarget? get currentTarget => _currentTarget;
  bool get hasPendingAutoFit => _hasPendingAutoFit && _currentTarget != null;
  bool get showResetCameraButton =>
      _currentTarget != null && _hasUserAdjustedCamera;

  bool syncTarget(RouteViewportTarget? target) {
    final previousContextKey = _currentTarget?.contextKey;
    _currentTarget = target;

    if (target == null) {
      _lastViewportContextKey = null;
      _hasUserAdjustedCamera = false;
      _isProgrammaticCameraMove = false;
      _hasPendingAutoFit = false;
      return false;
    }

    if (previousContextKey != target.contextKey ||
        _lastViewportContextKey != target.contextKey) {
      _lastViewportContextKey = target.contextKey;
      _hasUserAdjustedCamera = false;
      _hasPendingAutoFit = true;
      return true;
    }

    return false;
  }

  void markProgrammaticCameraMove() {
    if (_currentTarget == null) return;
    _hasPendingAutoFit = false;
    _hasUserAdjustedCamera = false;
    _isProgrammaticCameraMove = true;
  }

  bool handleCameraMoveStarted() {
    if (_currentTarget == null || _isProgrammaticCameraMove) return false;
    if (_hasUserAdjustedCamera) return false;
    _hasUserAdjustedCamera = true;
    return true;
  }

  bool handleCameraIdle() {
    if (!_isProgrammaticCameraMove) return false;
    _isProgrammaticCameraMove = false;
    return _hasUserAdjustedCamera;
  }
}

RouteViewportTarget? resolveRoutePreviewViewportTarget({
  required BookingFlowState flowState,
  required DirectionsResult? bookingDirections,
  required PlaceDetails? pickup,
  required PlaceDetails? destination,
  required BookingOriginSnapshot? originSnapshot,
  required Position? position,
  required ActiveRide? activeRide,
  required ActiveRideMapRouteQuery? activeRideRouteQuery,
}) {
  if (_isActiveRideFlow(flowState)) {
    return _resolveActiveRideViewportTarget(
      flowState: flowState,
      bookingDirections: bookingDirections,
      pickup: pickup,
      destination: destination,
      originSnapshot: originSnapshot,
      position: position,
      activeRide: activeRide,
      activeRideRouteQuery: activeRideRouteQuery,
    );
  }

  return _resolveBookingViewportTarget(
    bookingDirections: bookingDirections,
    pickup: pickup,
    destination: destination,
    originSnapshot: originSnapshot,
    position: position,
  );
}

bool _isActiveRideFlow(BookingFlowState flowState) {
  return flowState == BookingFlowState.driverAssigned ||
      flowState == BookingFlowState.arrived ||
      flowState == BookingFlowState.inProgress;
}

RouteViewportTarget? _resolveBookingViewportTarget({
  required DirectionsResult? bookingDirections,
  required PlaceDetails? pickup,
  required PlaceDetails? destination,
  required BookingOriginSnapshot? originSnapshot,
  required Position? position,
}) {
  if (bookingDirections == null || destination == null) return null;

  final origin = _firstValidLatLng([
    _toLatLngIfValid(pickup),
    _snapshotToLatLng(originSnapshot),
    _positionToLatLng(position),
  ]);
  final destinationLatLng = _toLatLngIfValid(destination);
  if (origin == null || destinationLatLng == null) return null;

  return RouteViewportTarget(
    contextKey:
        'booking:${_latLngKey(origin)}:${_latLngKey(destinationLatLng)}',
    origin: origin,
    destination: destinationLatLng,
  );
}

RouteViewportTarget? _resolveActiveRideViewportTarget({
  required BookingFlowState flowState,
  required DirectionsResult? bookingDirections,
  required PlaceDetails? pickup,
  required PlaceDetails? destination,
  required BookingOriginSnapshot? originSnapshot,
  required Position? position,
  required ActiveRide? activeRide,
  required ActiveRideMapRouteQuery? activeRideRouteQuery,
}) {
  if (activeRide == null) return null;

  if (flowState == BookingFlowState.driverAssigned ||
      flowState == BookingFlowState.arrived ||
      flowState == BookingFlowState.inProgress) {
    if (activeRideRouteQuery == null) return null;
    return RouteViewportTarget(
      contextKey:
          'active:${activeRide.rideId}:${activeRide.status.name}:${_latLngKey(activeRideRouteQuery.destination)}',
      origin: activeRideRouteQuery.origin,
      destination: activeRideRouteQuery.destination,
    );
  }

  return null;
}

LatLng? _toLatLngIfValid(PlaceDetails? place) {
  if (place == null) return null;
  return _validLatLng(LatLng(place.latitude, place.longitude));
}

LatLng? _snapshotToLatLng(BookingOriginSnapshot? snapshot) {
  if (snapshot == null) return null;
  return _validLatLng(LatLng(snapshot.latitude, snapshot.longitude));
}

LatLng? _positionToLatLng(Position? position) {
  if (position == null) return null;
  return _validLatLng(LatLng(position.latitude, position.longitude));
}

LatLng? _firstValidLatLng(List<LatLng?> candidates) {
  for (final candidate in candidates) {
    final valid = _validLatLng(candidate);
    if (valid != null) return valid;
  }
  return null;
}

LatLng? _validLatLng(LatLng? point) {
  if (point == null) return null;
  if (point.latitude < -90 || point.latitude > 90) return null;
  if (point.longitude < -180 || point.longitude > 180) return null;
  if (point.latitude == 0 && point.longitude == 0) return null;
  return point;
}

String _latLngKey(LatLng point) {
  return '${_rounded(point.latitude)},${_rounded(point.longitude)}';
}

double _rounded(double value) => (value * 10000).round() / 10000;
