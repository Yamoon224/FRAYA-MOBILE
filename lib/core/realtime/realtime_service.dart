library;

import 'realtime_events.dart';
import 'socket_health_state.dart';

abstract class RealtimeService {
  Stream<NearbyDriverMovingEvent> get nearbyDriverMovingStream;
  Stream<RideAcceptedEvent> get rideAcceptedStream;
  Stream<RidePositionUpdateEvent> get ridePositionUpdateStream;
  Stream<DriverRideStatusRealtimeEvent> get driverRideStatusStream;
  Stream<DriverRideStatusRealtimeEvent> get passengerRideLifecycleStream;
  Stream<NewRideOfferEvent> get newRideOfferStream;
  Stream<void> get forceLogoutStream;
  Stream<SocketHealthState> get healthStream;

  Future<void> connectPassenger({required String token, required int userId});

  Future<void> connectDriver({required String token, required int userId});

  Future<void> disconnect();
  void joinRide(int rideId);
  void dispose();
}
