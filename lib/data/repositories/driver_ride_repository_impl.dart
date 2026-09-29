library;

import 'package:fraya_mobile/domain/models/driver_ride.dart';
import 'package:fraya_mobile/domain/repositories/driver_ride_repository.dart';
import '../sources/remote/driver_ride_remote_data_source.dart';
import 'driver_ride_repository_filters.dart';

class DriverRideRepositoryImpl implements DriverRideRepository {
  DriverRideRepositoryImpl({
    required DriverRideRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final DriverRideRemoteDataSource _remoteDataSource;

  @override
  Future<List<DriverRide>> getHistoryRides() async {
    final rawData = await _remoteDataSource.getAllRides();
    return filterDriverHistoryRidesFromRaw(rawData);
  }

  @override
  Future<List<DriverRide>> getAvailableRides({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final rides = await _fetchAvailableDriverRides(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
    );
    return filterAvailableDriverRides(rides);
  }

  @override
  Future<DriverRide?> getActiveRide(int driverId, {String? rideId}) async {
    final raw = await _remoteDataSource.getActiveRideForDriver(driverId);
    if (raw == null) return null;
    final ride = DriverRide.fromMap(raw);
    if (!ride.isActiveForDriver) return null;
    if (rideId != null && rideId.isNotEmpty && ride.rideId != rideId) {
      return null;
    }
    return ride;
  }

  @override
  Future<void> acceptRide(
    String rideId, {
    required int driverId,
    required int vehicleId,
  }) {
    return _remoteDataSource.acceptRide(
      rideId,
      driverId: driverId,
      vehicleId: vehicleId,
    );
  }

  @override
  Future<void> markArrived(
    String rideId, {
    required double driverLat,
    required double driverLng,
  }) {
    return _remoteDataSource.markArrived(
      rideId,
      driverLat: driverLat,
      driverLng: driverLng,
    );
  }

  @override
  Future<void> startRide(String rideId) {
    return _remoteDataSource.startRide(rideId);
  }

  @override
  Future<void> completeRide(
    String rideId, {
    required double finalDistanceKm,
    required int finalDurationMin,
    required int finalPrice,
    required int additionnalFreeSeconds,
  }) {
    return _remoteDataSource.completeRide(
      rideId,
      finalDistanceKm: finalDistanceKm,
      finalDurationMin: finalDurationMin,
      finalPrice: finalPrice,
      additionnalFreeSeconds: additionnalFreeSeconds,
    );
  }

  @override
  Future<void> cancelRide(String rideId, {String? reason}) {
    return _remoteDataSource.cancelRide(rideId, reason: reason);
  }


  @override
  Future<void> sendLocation({
    required String rideId,
    required int driverId,
    required double lat,
    required double lng,
  }) {
    return _remoteDataSource.sendDriverLocation(
      rideId: rideId,
      driverId: driverId,
      lat: lat,
      lng: lng,
    );
  }

  @override
  Future<void> sendAvailabilityLocation({
    required double lat,
    required double lng,
  }) {
    return _remoteDataSource.sendDriverAvailabilityLocation(lat: lat, lng: lng);
  }

  Future<List<DriverRide>> _fetchAvailableDriverRides({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final data = await _remoteDataSource.getAvailableRides(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
    );
    return data.map(DriverRide.fromMap).toList();
  }
}
