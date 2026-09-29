import '../../../../core/realtime/socket_health_state.dart';
import '../../../../domain/models/active_ride.dart';
import '../../../../domain/models/ride_status.dart';

ActiveRide mergeBackendRideWithRealtimeLocation({
  required ActiveRide backendRide,
  required ActiveRide? currentRide,
  required SocketHealthState socketHealth,
}) {
  if (currentRide == null || currentRide.rideId != backendRide.rideId) {
    return backendRide;
  }
  if (!_tracksDriver(currentRide.status) ||
      !_tracksDriver(backendRide.status)) {
    return backendRide;
  }
  if (!_prefersRealtimeLocation(socketHealth)) return backendRide;
  return backendRide.copyWith(driverLocation: currentRide.driverLocation);
}

bool _tracksDriver(RideStatus status) {
  return status == RideStatus.accepted ||
      status == RideStatus.arrived ||
      status == RideStatus.inProgress;
}

bool _prefersRealtimeLocation(SocketHealthState health) {
  return health == SocketHealthState.connected ||
      health == SocketHealthState.reconnecting;
}
