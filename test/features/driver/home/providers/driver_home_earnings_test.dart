import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/driver_ride_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/accept_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/cancel_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/complete_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/fetch_available_driver_rides.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/get_driver_active_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/mark_driver_ride_arrived.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/start_driver_ride.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_notifier.dart';
import 'package:fraya_mobile/domain/repositories/driver_status_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/status/update_driver_status.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EarningsDriverRideRepository implements DriverRideRepository {
  DriverRide? activeRide;

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
  }) async {
    activeRide = null;
  }

  @override
  Future<List<DriverRide>> getAvailableRides({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async => const [];

  @override
  Future<DriverRide?> getActiveRide(int driverId, {String? rideId}) async {
    return activeRide;
  }

  @override
  Future<List<DriverRide>> getHistoryRides() async => const [];

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

class _NoopDriverStatusRepository implements DriverStatusRepository {
  @override
  Future<void> updateStatus({required bool isOnline}) async {}

  @override
  Future<void> sendHeartbeat() async {}
}

void main() {
  test(
    'completeRide updates earnings summary and recent completed rides',
    () async {
      final repository = EarningsDriverRideRepository()
        ..activeRide = _ride(status: RideStatus.inProgress);
      final notifier = DriverHomeNotifier(
        acceptRideUseCase: AcceptDriverRideUseCase(repository),
        markArrivedUseCase: MarkDriverRideArrivedUseCase(repository),
        startRideUseCase: StartDriverRideUseCase(repository),
        completeRideUseCase: CompleteDriverRideUseCase(repository),
        cancelRideUseCase: CancelDriverRideUseCase(repository),
        fetchAvailableRidesUseCase: FetchAvailableDriverRidesUseCase(
          repository,
        ),
        getActiveRideUseCase: GetDriverActiveRideUseCase(repository),
        updateDriverStatusUseCase: UpdateDriverStatusUseCase(
          _NoopDriverStatusRepository(),
        ),
      );

      notifier.syncUserData(const {
        'userId': 24,
        'driverId': 14,
        'kycStatus': 'APPROVED',
        'vehicleStatus': 'APPROVED',
        'vehicleId': 7,
      });
      await notifier.setOnline(true);
      await notifier.completeRide(
        rideId: 'ride-1',
        finalDistanceKm: 9.2,
        finalDurationMin: 23,
        finalPrice: 4750,
      );

      expect(notifier.state.todayRideCount, 1);
      expect(notifier.state.todayEarnings, 4750);
      expect(notifier.state.todayCompletedRides, hasLength(1));
      expect(notifier.state.knownCompletedRides, hasLength(1));
      expect(
        notifier.state.todayCompletedRides.first.status,
        RideStatus.completed,
      );
      expect(notifier.state.todayCompletedRides.first.finalPrice, 4750);
      expect(notifier.state.todayCompletedRides.first.estimatedDurationMin, 23);

      notifier.dispose();
    },
  );
}

DriverRide _ride({required RideStatus status}) {
  return DriverRide(
    rideId: 'ride-1',
    status: status,
    passengerName: 'Kouadio Jean',
    pickupAddress: 'Cocody Angre, 8eme tranche',
    destinationAddress: 'Plateau, Immeuble SCIAM',
    pickupLocation: const LatLng(5.4, -3.96),
    destinationLocation: const LatLng(5.32, -4.01),
    requestedRange: 'MAGIC',
    estimatedPrice: 3500,
    estimatedDistanceKm: 8.5,
    estimatedDurationMin: 18,
    assignedDriverId: 14,
    vehicleId: 7,
    createdAt: DateTime(2026, 2, 24, 18, 15),
    updatedAt: DateTime(2026, 2, 24, 18, 37),
  );
}
