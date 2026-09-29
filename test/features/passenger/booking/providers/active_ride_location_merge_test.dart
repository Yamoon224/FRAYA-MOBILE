import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/realtime/socket_health_state.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_location_merge.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test('connected socket location wins over polling for the same ride', () {
    final merged = mergeBackendRideWithRealtimeLocation(
      backendRide: _ride(const LatLng(5.31, -4.01)),
      currentRide: _ride(const LatLng(5.35, -3.98)),
      socketHealth: SocketHealthState.connected,
    );

    expect(merged.driverLocation, const LatLng(5.35, -3.98));
  });

  test('backend location is used while realtime is offline', () {
    final merged = mergeBackendRideWithRealtimeLocation(
      backendRide: _ride(const LatLng(5.31, -4.01)),
      currentRide: _ride(const LatLng(5.35, -3.98)),
      socketHealth: SocketHealthState.offline,
    );

    expect(merged.driverLocation, const LatLng(5.31, -4.01));
  });

  test('backend location is used when polling returns another ride', () {
    final merged = mergeBackendRideWithRealtimeLocation(
      backendRide: _ride(const LatLng(5.31, -4.01)),
      currentRide: _ride(const LatLng(5.35, -3.98), rideId: 'ride-99'),
      socketHealth: SocketHealthState.connected,
    );

    expect(merged.driverLocation, const LatLng(5.31, -4.01));
  });

  test('first assigned driver location is accepted after a pending ride', () {
    final merged = mergeBackendRideWithRealtimeLocation(
      backendRide: _ride(const LatLng(5.31, -4.01)),
      currentRide: _ride(const LatLng(5.35, -3.98), status: RideStatus.pending),
      socketHealth: SocketHealthState.connected,
    );

    expect(merged.driverLocation, const LatLng(5.31, -4.01));
  });
}

ActiveRide _ride(
  LatLng driverLocation, {
  String rideId = 'ride-42',
  RideStatus status = RideStatus.inProgress,
}) {
  return ActiveRide(
    rideId: rideId,
    driverName: 'Jean',
    driverPhoto: 'assets/images/driver_placeholder.png',
    driverRating: 4.8,
    carModel: 'Toyota',
    carPlate: 'AB-123-CD',
    driverLocation: driverLocation,
    pickupLocation: const LatLng(5.31, -4.01),
    destinationLocation: const LatLng(5.25, -3.93),
    status: status,
    estimatedPrice: 2500,
  );
}
