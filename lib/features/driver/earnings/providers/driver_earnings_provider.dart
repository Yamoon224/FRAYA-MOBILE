library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;

import '../../../../domain/models/driver_ride.dart';
import '../../../../domain/models/driver_ride_earnings.dart';
import '../../../../domain/models/ride_status.dart';
import '../../history/models/driver_history_day_section.dart';
import '../../history/providers/driver_history_filter_provider.dart';
import '../../history/providers/driver_history_provider.dart';
import '../models/driver_earnings_summary.dart';
import '../services/driver_earnings_export_service.dart';

enum DriverEarningsPeriod { today, sevenDays, thirtyDays }

class DriverEarningsFilterState {
  const DriverEarningsFilterState({
    this.period = DriverEarningsPeriod.today,
    this.customRange,
  });

  final DriverEarningsPeriod period;
  final DateTimeRange? customRange;

  DriverEarningsFilterState copyWith({
    DriverEarningsPeriod? period,
    Object? customRange = _sentinel,
  }) {
    return DriverEarningsFilterState(
      period: period ?? this.period,
      customRange: identical(customRange, _sentinel)
          ? this.customRange
          : customRange as DateTimeRange?,
    );
  }
}

class DriverEarningsFilterController
    extends StateNotifier<DriverEarningsFilterState> {
  DriverEarningsFilterController() : super(const DriverEarningsFilterState());

  void setPeriod(DriverEarningsPeriod period) {
    state = DriverEarningsFilterState(period: period);
  }

  void setCustomRange(DateTimeRange range) {
    state = state.copyWith(customRange: range);
  }

  void clearCustomRange() {
    state = state.copyWith(customRange: null);
  }
}

final driverEarningsFilterProvider =
    StateNotifierProvider<
      DriverEarningsFilterController,
      DriverEarningsFilterState
    >((ref) => DriverEarningsFilterController());

final completedDriverEarningsRidesProvider = Provider<List<DriverRide>>((ref) {
  final rides = ref.watch(allDriverHistoryRidesProvider);
  return rides.where((ride) => ride.status == RideStatus.completed).toList();
});

final filteredDriverEarningsRidesProvider = Provider<List<DriverRide>>((ref) {
  final rides = ref.watch(completedDriverEarningsRidesProvider);
  final filter = ref.watch(driverEarningsFilterProvider);

  if (filter.customRange != null) {
    return applyDriverHistoryFilter(
      rides,
      DriverHistoryFilterState(customRange: filter.customRange),
    );
  }

  final quickFilter = switch (filter.period) {
    DriverEarningsPeriod.sevenDays => DriverHistoryQuickFilter.sevenDays,
    DriverEarningsPeriod.thirtyDays => DriverHistoryQuickFilter.thirtyDays,
    DriverEarningsPeriod.today => DriverHistoryQuickFilter.today,
  };
  return applyDriverHistoryFilter(
    rides,
    DriverHistoryFilterState(quickFilter: quickFilter),
  );
});

final driverEarningsSectionsProvider = Provider<List<DriverHistoryDaySection>>((
  ref,
) {
  final rides = ref.watch(filteredDriverEarningsRidesProvider);
  return buildDriverHistorySections(rides);
});

final driverEarningsSummaryProvider = Provider<DriverEarningsSummary>((ref) {
  final rides = ref.watch(filteredDriverEarningsRidesProvider);
  return buildDriverEarningsSummary(rides);
});

final driverEarningsExportServiceProvider =
    Provider<DriverEarningsExportService>((ref) {
      return DriverEarningsExportService();
    });

DriverEarningsSummary buildDriverEarningsSummary(List<DriverRide> rides) {
  final rideCount = rides.length;
  final totalEarnings = rides.fold<double>(
    0,
    (sum, ride) => sum + ride.driverEarningsAmount,
  );
  final totalCommission = rides.fold<double>(
    0,
    (sum, ride) => sum + ride.driverCommissionAmount,
  );
  final totalTripMinutes = rides.fold<int>(
    0,
    (sum, ride) => sum + ride.tripDurationMinutes,
  );
  final averagePerRide = rideCount == 0 ? 0.0 : totalEarnings / rideCount;
  final earningsPerTripHour = totalTripMinutes <= 0
      ? 0.0
      : totalEarnings / (totalTripMinutes / 60);

  return DriverEarningsSummary(
    completedRideCount: rideCount,
    totalEarnings: totalEarnings,
    totalCommission: totalCommission,
    totalNetEarnings: totalEarnings - totalCommission,
    totalTripMinutes: totalTripMinutes,
    averagePerRide: averagePerRide,
    earningsPerTripHour: earningsPerTripHour,
  );
}

const Object _sentinel = Object();
