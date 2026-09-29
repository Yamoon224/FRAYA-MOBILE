import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/driver/history/providers/driver_history_filter_provider.dart';
import 'package:fraya_mobile/features/driver/history/providers/driver_history_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_ride_dependencies.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  test(
    'builds stats from completed rides and keeps cancelled rides in history',
    () async {
      final now = DateTime.now();
      final repository = FakeDriverRideRepository()
        ..historyRides = [
          buildDriverRide(
            id: 'ride-completed-today',
            status: RideStatus.completed,
            finalPrice: 4700,
            completedAt: now.subtract(const Duration(hours: 1)),
            driverRatingFromPassenger: 5,
          ),
          buildDriverRide(
            id: 'ride-cancelled-today',
            status: RideStatus.cancelled,
            estimatedPrice: 2500,
            cancelledAt: now.subtract(const Duration(hours: 2)),
          ),
          buildDriverRide(
            id: 'ride-completed-old',
            status: RideStatus.completed,
            finalPrice: 3200,
            completedAt: now.subtract(const Duration(days: 10)),
            driverRatingFromPassenger: 3,
          ),
        ];
      final container = ProviderContainer(
        overrides: [driverRideRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(driverHistoryRidesProvider.future);

      final todayStats = container.read(todayDriverHistoryStatsProvider);
      final allStats = container.read(allDriverHistoryStatsProvider);
      final todayRides = container.read(todayDriverHistoryRidesProvider);
      final sections = container.read(driverHistorySectionsProvider);

      expect(todayStats.completedRideCount, 1);
      expect(todayStats.earnings, 4700);
      expect(todayStats.averageRating, 5);
      expect(todayStats.ratedRideCount, 1);
      expect(allStats.completedRideCount, 2);
      expect(allStats.earnings, 7900);
      expect(allStats.averageRating, 4);
      expect(allStats.ratedRideCount, 2);
      expect(todayRides, hasLength(2));
      expect(sections.first.title, 'Aujourd\'hui');
      expect(sections.first.rides, hasLength(2));
      expect(sections.last.rides.single.rideId, 'ride-completed-old');
    },
  );

  test('applies quick filters and custom range on history rides', () async {
    final now = DateTime.now();
    final oldDay = now.subtract(const Duration(days: 20));
    final repository = FakeDriverRideRepository()
      ..historyRides = [
        buildDriverRide(
          id: 'recent-completed',
          status: RideStatus.completed,
          finalPrice: 4700,
          completedAt: now.subtract(const Duration(hours: 1)),
          driverRatingFromPassenger: 5,
        ),
        buildDriverRide(
          id: 'recent-cancelled',
          status: RideStatus.cancelled,
          cancelledAt: now.subtract(const Duration(days: 6)),
        ),
        buildDriverRide(
          id: 'old-completed',
          status: RideStatus.completed,
          finalPrice: 3200,
          completedAt: oldDay,
          driverRatingFromPassenger: 3,
        ),
      ];
    final container = ProviderContainer(
      overrides: [driverRideRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(driverHistoryRidesProvider.future);

    expect(container.read(filteredDriverHistoryRidesProvider), hasLength(3));

    container
        .read(driverHistoryFilterControllerProvider.notifier)
        .setQuickFilter(DriverHistoryQuickFilter.sevenDays);
    expect(container.read(filteredDriverHistoryRidesProvider), hasLength(2));
    expect(container.read(filteredDriverHistoryStatsProvider).averageRating, 5);

    container
        .read(driverHistoryFilterControllerProvider.notifier)
        .setCustomRange(DateTimeRange(start: oldDay, end: oldDay));
    final customRangeRides = container.read(filteredDriverHistoryRidesProvider);
    expect(customRangeRides, hasLength(1));
    expect(customRangeRides.single.rideId, 'old-completed');
    expect(container.read(filteredDriverHistoryStatsProvider).averageRating, 3);
  });
}
