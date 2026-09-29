import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/accept_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/cancel_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/complete_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/fetch_available_driver_rides.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/get_driver_active_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/mark_driver_ride_arrived.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/start_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/status/update_driver_status.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_notifier.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  group('DriverHomeNotifier double submission guard', () {
    test('prevents duplicate critical actions beyond accept', () async {
      Future<void> runGuardCase({
        required String rideId,
        required RideStatus status,
        required Future<bool> Function(DriverHomeNotifier notifier) trigger,
        required int Function(FakeDriverRideRepository repository) calls,
      }) async {
        final repository = FakeDriverRideRepository()
          ..activeRide = buildDriverRide(id: rideId, status: status)
          ..pendingActionCompleter = Completer<void>();
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
            FakeDriverStatusRepository(),
          ),
        );
        notifier.syncUserData(_approvedUserData);
        await notifier.setOnline(true);

        final firstCall = trigger(notifier);
        final secondResult = await trigger(notifier);
        repository.pendingActionCompleter!.complete();
        final firstResult = await firstCall;

        expect(firstResult, isTrue);
        expect(secondResult, isFalse);
        expect(calls(repository), 1);
        notifier.dispose();
      }

      await runGuardCase(
        rideId: 'arrived-1',
        status: RideStatus.accepted,
        trigger: (notifier) => notifier.markArrivedForRide(
          buildDriverRide(id: 'arrived-1', status: RideStatus.accepted),
        ),
        calls: (repository) => repository.markArrivedCalls,
      );
      await runGuardCase(
        rideId: 'start-1',
        status: RideStatus.arrived,
        trigger: (notifier) => notifier.startRide('start-1'),
        calls: (repository) => repository.startRideCalls,
      );
      await runGuardCase(
        rideId: 'complete-1',
        status: RideStatus.inProgress,
        trigger: (notifier) => notifier.completeRide(
          rideId: 'complete-1',
          finalDistanceKm: 8.4,
          finalDurationMin: 18,
          finalPrice: 3200,
        ),
        calls: (repository) => repository.completeRideCalls,
      );
      await runGuardCase(
        rideId: 'cancel-1',
        status: RideStatus.accepted,
        trigger: (notifier) =>
            notifier.cancelRide(rideId: 'cancel-1', reason: 'test'),
        calls: (repository) => repository.cancelRideCalls,
      );
    });
  });
}

const _approvedUserData = {
  'userId': 24,
  'driverId': 14,
  'kycStatus': 'APPROVED',
  'vehicleStatus': 'APPROVED',
  'vehicleId': 7,
};
