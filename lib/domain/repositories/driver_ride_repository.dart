library;

import '../models/driver_ride.dart';

abstract class DriverRideRepository {
  Future<List<DriverRide>> getHistoryRides();

  Future<List<DriverRide>> getAvailableRides({
    required double lat,
    required double lng,
    required double radiusKm,
  });

  Future<DriverRide?> getActiveRide(int driverId, {String? rideId});

  Future<void> acceptRide(
    String rideId, {
    required int driverId,
    required int vehicleId,
  });

  Future<void> markArrived(
    String rideId, {
    required double driverLat,
    required double driverLng,
  });

  Future<void> startRide(String rideId);

  Future<void> completeRide(
    String rideId, {
    required double finalDistanceKm,
    required int finalDurationMin,
    required int finalPrice,
    required int additionnalFreeSeconds,
  });

  Future<void> cancelRide(String rideId, {String? reason});

  Future<void> sendLocation({
    required String rideId,
    required int driverId,
    required double lat,
    required double lng,
  });

  Future<void> sendAvailabilityLocation({
    required double lat,
    required double lng,
  });
}
