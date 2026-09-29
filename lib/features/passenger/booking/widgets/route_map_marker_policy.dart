import '../models/booking_flow_state.dart';

enum RouteMapDriverLayerMode { nearbyOnly, activeRideOnly }

RouteMapDriverLayerMode resolveDriverLayerMode({
  required BookingFlowState flowState,
  required bool hasActiveRide,
}) {
  if (!hasActiveRide) return RouteMapDriverLayerMode.nearbyOnly;

  switch (flowState) {
    case BookingFlowState.driverAssigned:
    case BookingFlowState.arrived:
    case BookingFlowState.inProgress:
    case BookingFlowState.completed:
      return RouteMapDriverLayerMode.activeRideOnly;
    case BookingFlowState.idle:
    case BookingFlowState.routePreview:
    case BookingFlowState.searching:
    case BookingFlowState.searchFailed:
    case BookingFlowState.activeRideConflict:
      return RouteMapDriverLayerMode.nearbyOnly;
  }
}
