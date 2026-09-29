import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_state.dart';
import 'package:fraya_mobile/features/driver/status/providers/driver_ride_completion_controller.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  test('updateRating toggles to zero when tapping same star again', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(
      driverRideCompletionControllerProvider.notifier,
    );

    controller.updateRating(5);
    expect(container.read(driverRideCompletionControllerProvider).rating, 5);

    controller.updateRating(5);
    expect(container.read(driverRideCompletionControllerProvider).rating, 0);
  });

  test('submit sends zero waiting fields when ride has no paid wait', () async {
    final repository = FakeDriverRideRepository();
    final ride = _ride(
      arrivedAt: DateTime(2026, 6, 5, 10),
      startedAt: DateTime(2026, 6, 5, 10, 5),
    );
    final container = _container(repository, ride);
    addTearDown(container.dispose);

    final success = await container
        .read(driverRideCompletionControllerProvider.notifier)
        .submit(ride);

    expect(success, isTrue);
    expect(repository.lastFinalPrice, 3500);
    expect(repository.lastAdditionnalFreeSeconds, 0);
  });

  test('submit sends paid waiting fields after free minutes', () async {
    final repository = FakeDriverRideRepository();
    final ride = _ride(
      arrivedAt: DateTime(2026, 6, 5, 10),
      startedAt: DateTime(2026, 6, 5, 10, 7),
    );
    final container = _container(repository, ride);
    addTearDown(container.dispose);

    final success = await container
        .read(driverRideCompletionControllerProvider.notifier)
        .submit(ride);

    expect(success, isTrue);
    expect(repository.lastFinalPrice, 3700);
    expect(repository.lastAdditionnalFreeSeconds, 120);
  });

  test('submit rounds up started paid waiting minute', () async {
    final repository = FakeDriverRideRepository();
    final ride = _ride(
      arrivedAt: DateTime(2026, 6, 5, 10),
      startedAt: DateTime(2026, 6, 5, 10, 5, 1),
    );
    final container = _container(repository, ride);
    addTearDown(container.dispose);

    final success = await container
        .read(driverRideCompletionControllerProvider.notifier)
        .submit(ride);

    expect(success, isTrue);
    expect(repository.lastFinalPrice, 3600);
    expect(repository.lastAdditionnalFreeSeconds, 1);
  });

  test(
    'submit sends zero waiting fields when arrival time is missing',
    () async {
      final repository = FakeDriverRideRepository();
      final ride = _ride(startedAt: DateTime(2026, 6, 5, 10, 7));
      final container = _container(repository, ride);
      addTearDown(container.dispose);

      final success = await container
          .read(driverRideCompletionControllerProvider.notifier)
          .submit(ride);

      expect(success, isTrue);
      expect(repository.lastFinalPrice, 3500);
      expect(repository.lastAdditionnalFreeSeconds, 0);
    },
  );
}

ProviderContainer _container(
  FakeDriverRideRepository repository,
  DriverRide ride,
) {
  repository.activeRide = ride;
  final notifier = FakeDriverHomeNotifier(
    repository,
    DriverHomeState(activeRide: ride, isOnline: true, canGoOnline: true),
  )..syncUserData(_approvedDriver);
  return ProviderContainer(
    overrides: [driverHomeProvider.overrideWith((ref) => notifier)],
  );
}

DriverRide _ride({DateTime? arrivedAt, DateTime? startedAt}) {
  return buildDriverRide(
    id: 'ride-complete',
    status: RideStatus.inProgress,
    arrivedAt: arrivedAt,
    startedAt: startedAt,
    estimatedPrice: 3200,
    finalPrice: 3500,
  );
}

const _approvedDriver = {
  'userId': 24,
  'driverId': 14,
  'kycStatus': 'APPROVED',
  'vehicleStatus': 'APPROVED',
  'vehicleId': 7,
};
