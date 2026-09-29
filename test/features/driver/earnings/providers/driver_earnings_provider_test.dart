import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/driver/earnings/providers/driver_earnings_provider.dart';
import 'package:fraya_mobile/features/driver/history/providers/driver_history_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_ride_dependencies.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  test('computes earnings summary and filters by period', () async {
    final now = DateTime.now();
    final repository = FakeDriverRideRepository()
      ..historyRides = [
        buildDriverRide(
          id: 'ride-today',
          status: RideStatus.completed,
          finalPrice: 4500,
          completedAt: now.subtract(const Duration(hours: 2)),
          estimatedDurationMin: 30,
        ),
        buildDriverRide(
          id: 'ride-week',
          status: RideStatus.completed,
          finalPrice: 3000,
          completedAt: now.subtract(const Duration(days: 5)),
          estimatedDurationMin: 15,
        ),
        buildDriverRide(
          id: 'ride-month',
          status: RideStatus.completed,
          finalPrice: 2800,
          completedAt: now.subtract(const Duration(days: 20)),
          estimatedDurationMin: 20,
        ),
        buildDriverRide(
          id: 'ride-cancelled',
          status: RideStatus.cancelled,
          cancelledAt: now.subtract(const Duration(days: 1)),
        ),
      ];
    final container = ProviderContainer(
      overrides: [driverRideRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(driverHistoryRidesProvider.future);

    final todaySummary = container.read(driverEarningsSummaryProvider);
    expect(todaySummary.completedRideCount, 1);
    expect(todaySummary.totalEarnings, 4500);
    expect(todaySummary.totalTripMinutes, 30);

    container
        .read(driverEarningsFilterProvider.notifier)
        .setPeriod(DriverEarningsPeriod.sevenDays);
    final weekSummary = container.read(driverEarningsSummaryProvider);
    expect(weekSummary.completedRideCount, 2);
    expect(weekSummary.totalEarnings, 7500);

    container
        .read(driverEarningsFilterProvider.notifier)
        .setPeriod(DriverEarningsPeriod.thirtyDays);
    final monthSummary = container.read(driverEarningsSummaryProvider);
    expect(monthSummary.completedRideCount, 3);
    expect(monthSummary.totalEarnings, 10300);
  });
}
