import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fraya_mobile/domain/models/driver_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/driver_ride_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/fetch_available_driver_rides.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/get_driver_active_ride.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_ride_loader.dart';

class _StubRideRepository implements DriverRideRepository {
  List<DriverRide> availableRides = [];
  DriverRide? activeRide;

  @override
  Future<List<DriverRide>> getAvailableRides({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async => availableRides;

  @override
  Future<DriverRide?> getActiveRide(int driverId, {String? rideId}) async =>
      activeRide;

  @override
  Future<List<DriverRide>> getHistoryRides() async => [];

  @override
  Future<void> acceptRide(
    String rideId, {
    required int driverId,
    required int vehicleId,
  }) async {}

  @override
  Future<void> cancelRide(String rideId, {String? reason}) async {}

  @override
  Future<void> completeRide(
    String rideId, {
    required double finalDistanceKm,
    required int finalDurationMin,
    required int finalPrice,
    required int additionnalFreeSeconds,
  }) async {}

  @override
  Future<void> markArrived(
    String rideId, {
    required double driverLat,
    required double driverLng,
  }) async {}

  @override
  Future<void> startRide(String rideId) async {}

  @override
  Future<void> sendLocation({
    required String rideId,
    required int driverId,
    required double lat,
    required double lng,
  }) async {}

  @override
  Future<void> sendAvailabilityLocation({
    required double lat,
    required double lng,
  }) async {}
}

DriverRide _ride({
  required String id,
  RideStatus status = RideStatus.accepted,
}) {
  return DriverRide(
    rideId: id,
    status: status,
    passengerName: 'Alice Kouassi',
    pickupAddress: 'Cocody Angre',
    destinationAddress: 'Plateau Centre',
    pickupLocation: const LatLng(5.4, -3.9),
    destinationLocation: const LatLng(5.32, -4.01),
    requestedRange: 'MAGIC',
    estimatedPrice: 3200,
    estimatedDistanceKm: 8.4,
    estimatedDurationMin: 18,
    assignedDriverId: 14,
    vehicleId: 7,
    createdAt: DateTime(2026, 2, 24, 10),
    updatedAt: DateTime(2026, 2, 24, 10, 5),
  );
}

DriverHomeRideLoader _loader(_StubRideRepository repo) {
  return DriverHomeRideLoader(
    fetchAvailableRidesUseCase: FetchAvailableDriverRidesUseCase(repo),
    getActiveRideUseCase: GetDriverActiveRideUseCase(repo),
  );
}

void main() {
  group('DriverHomeRideLoader.refresh', () {
    test('loads available rides when no activeRideId', () async {
      final repo = _StubRideRepository()
        ..availableRides = [_ride(id: 'r-1', status: RideStatus.pending)];
      final result = await _loader(repo).refresh(
        driverId: 1,
        activeRideId: null,
        driverLat: 5.36,
        driverLng: -4.008,
      );

      expect(result.activeRide, isNull);
      expect(result.availableRides, hasLength(1));
    });

    test('loads only active ride when fetchAvailableRides is false', () async {
      final repo = _StubRideRepository()
        ..activeRide = _ride(id: 'r-2')
        ..availableRides = [_ride(id: 'r-x', status: RideStatus.pending)];
      final result = await _loader(repo).refresh(
        driverId: 1,
        activeRideId: 'r-2',
        driverLat: 5.36,
        driverLng: -4.008,
        fetchAvailableRides: false,
      );

      expect(result.activeRide?.rideId, 'r-2');
      expect(result.availableRides, isEmpty);
    });

    test(
      'loads both active ride and available rides when fetchAvailableRides is true',
      () async {
        final repo = _StubRideRepository()
          ..activeRide = _ride(id: 'r-3')
          ..availableRides = [_ride(id: 'r-4', status: RideStatus.pending)];
        final result = await _loader(repo).refresh(
          driverId: 1,
          activeRideId: 'r-3',
          driverLat: 5.36,
          driverLng: -4.008,
          fetchAvailableRides: true,
        );

        expect(result.activeRide?.rideId, 'r-3');
        expect(result.availableRides, hasLength(1));
        expect(result.availableRides.first.rideId, 'r-4');
      },
    );

    test(
      'falls back to available rides when active ride is not found',
      () async {
        final repo = _StubRideRepository()
          ..activeRide = null
          ..availableRides = [_ride(id: 'r-5', status: RideStatus.pending)];
        final result = await _loader(repo).refresh(
          driverId: 1,
          activeRideId: 'r-missing',
          driverLat: 5.36,
          driverLng: -4.008,
          fetchAvailableRides: true,
        );

        expect(result.activeRide, isNull);
        expect(result.availableRides, hasLength(1));
      },
    );
  });
}
