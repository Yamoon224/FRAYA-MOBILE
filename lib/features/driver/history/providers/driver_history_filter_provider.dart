library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart';

import '../../../../domain/models/driver_ride.dart';
import '../models/driver_history_day_section.dart';
import '../models/driver_history_stats.dart';
import 'driver_history_provider.dart';

enum DriverHistoryQuickFilter { today, sevenDays, thirtyDays, all }

class DriverHistoryFilterState {
  const DriverHistoryFilterState({
    this.quickFilter = DriverHistoryQuickFilter.all,
    this.customRange,
  });

  final DriverHistoryQuickFilter quickFilter;
  final DateTimeRange? customRange;

  DriverHistoryFilterState copyWith({
    DriverHistoryQuickFilter? quickFilter,
    Object? customRange = _sentinel,
  }) {
    return DriverHistoryFilterState(
      quickFilter: quickFilter ?? this.quickFilter,
      customRange: identical(customRange, _sentinel)
          ? this.customRange
          : customRange as DateTimeRange?,
    );
  }
}

class DriverHistoryFilterController
    extends StateNotifier<DriverHistoryFilterState> {
  DriverHistoryFilterController() : super(const DriverHistoryFilterState());

  void setQuickFilter(DriverHistoryQuickFilter filter) {
    state = DriverHistoryFilterState(quickFilter: filter);
  }

  void setCustomRange(DateTimeRange range) {
    state = state.copyWith(customRange: range);
  }

  void clearCustomRange() {
    state = state.copyWith(customRange: null);
  }
}

final driverHistoryFilterControllerProvider =
    StateNotifierProvider<
      DriverHistoryFilterController,
      DriverHistoryFilterState
    >((ref) {
      return DriverHistoryFilterController();
    });

final filteredDriverHistoryRidesProvider = Provider<List<DriverRide>>((ref) {
  final rides = ref.watch(allDriverHistoryRidesProvider);
  final filter = ref.watch(driverHistoryFilterControllerProvider);
  return applyDriverHistoryFilter(rides, filter);
});

final driverHistorySectionsProvider = Provider<List<DriverHistoryDaySection>>((
  ref,
) {
  final rides = ref.watch(filteredDriverHistoryRidesProvider);
  return buildDriverHistorySections(rides);
});

final filteredDriverHistoryStatsProvider = Provider<DriverHistoryStats>((ref) {
  final rides = ref.watch(filteredDriverHistoryRidesProvider);
  return buildDriverHistoryStats(rides);
});

List<DriverRide> applyDriverHistoryFilter(
  List<DriverRide> rides,
  DriverHistoryFilterState filter,
) {
  if (filter.customRange != null) {
    return rides
        .where(
          (ride) => _isWithinCustomRange(ride.historyDate, filter.customRange!),
        )
        .toList();
  }

  final today = _startOfDay(DateTime.now())!;
  return switch (filter.quickFilter) {
    DriverHistoryQuickFilter.today =>
      rides.where((ride) => _startOfDay(ride.historyDate) == today).toList(),
    DriverHistoryQuickFilter.sevenDays => _filterSince(
      rides,
      today.subtract(const Duration(days: 6)),
    ),
    DriverHistoryQuickFilter.thirtyDays => _filterSince(
      rides,
      today.subtract(const Duration(days: 29)),
    ),
    DriverHistoryQuickFilter.all => rides,
  };
}

List<DriverHistoryDaySection> buildDriverHistorySections(
  List<DriverRide> rides,
) {
  final sections = <DriverHistoryDaySection>[];
  final grouped = <DateTime, List<DriverRide>>{};

  for (final ride in rides) {
    final day = _startOfDay(ride.historyDate);
    if (day == null) {
      continue;
    }
    grouped.putIfAbsent(day, () => <DriverRide>[]).add(ride);
  }

  final sortedDays = grouped.keys.toList()
    ..sort((left, right) => right.compareTo(left));
  for (final day in sortedDays) {
    final sectionRides = grouped[day]!;
    sections.add(
      DriverHistoryDaySection(
        day: day,
        title: formatDriverHistoryDay(day),
        rides: sectionRides,
      ),
    );
  }
  return sections;
}

List<DriverRide> _filterSince(List<DriverRide> rides, DateTime start) {
  return rides.where((ride) {
    final day = _startOfDay(ride.historyDate);
    return day != null && !day.isBefore(start);
  }).toList();
}

bool _isWithinCustomRange(DateTime? date, DateTimeRange range) {
  final day = _startOfDay(date);
  if (day == null) {
    return false;
  }
  final start = _startOfDay(range.start)!;
  final end = _startOfDay(range.end)!;
  return !day.isBefore(start) && !day.isAfter(end);
}

DateTime? _startOfDay(DateTime? date) {
  if (date == null) {
    return null;
  }
  final localDate = date.toLocal();
  return DateTime(localDate.year, localDate.month, localDate.day);
}

const Object _sentinel = Object();
