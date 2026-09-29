import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/models/ride_model.dart';
import 'history_provider.dart';

enum HistoryQuickFilter { today, sevenDays, thirtyDays, all }

class HistoryFilterState {
  const HistoryFilterState({
    this.quickFilter = HistoryQuickFilter.all,
    this.customRange,
  });

  final HistoryQuickFilter quickFilter;
  final DateTimeRange? customRange;

  HistoryFilterState copyWith({
    HistoryQuickFilter? quickFilter,
    Object? customRange = _sentinel,
  }) {
    return HistoryFilterState(
      quickFilter: quickFilter ?? this.quickFilter,
      customRange: identical(customRange, _sentinel)
          ? this.customRange
          : customRange as DateTimeRange?,
    );
  }
}

class HistoryFilterController extends StateNotifier<HistoryFilterState> {
  HistoryFilterController() : super(const HistoryFilterState());

  void setQuickFilter(HistoryQuickFilter filter) {
    state = HistoryFilterState(quickFilter: filter);
  }

  void setCustomRange(DateTimeRange range) {
    state = state.copyWith(customRange: range);
  }

  void clearCustomRange() {
    state = state.copyWith(customRange: null);
  }
}

final historyFilterControllerProvider =
    StateNotifierProvider<HistoryFilterController, HistoryFilterState>((ref) {
  return HistoryFilterController();
});

final filteredRidesProvider = Provider<List<Ride>>((ref) {
  final rides = ref.watch(allRidesProvider);
  final filter = ref.watch(historyFilterControllerProvider);
  return applyHistoryFilter(rides, filter);
});

List<Ride> applyHistoryFilter(
  List<Ride> rides,
  HistoryFilterState filter,
) {
  final sorted = List<Ride>.from(rides)
    ..sort((left, right) => right.date.compareTo(left.date));
  if (filter.customRange != null) {
    return sorted
        .where((ride) => _isWithinCustomRange(ride.date, filter.customRange!))
        .toList();
  }

  final today = _startOfDay(DateTime.now());
  switch (filter.quickFilter) {
    case HistoryQuickFilter.today:
      return sorted
          .where((ride) => _startOfDay(ride.date) == today)
          .toList();
    case HistoryQuickFilter.sevenDays:
      final start = today.subtract(const Duration(days: 6));
      return sorted
          .where((ride) => !_startOfDay(ride.date).isBefore(start))
          .toList();
    case HistoryQuickFilter.thirtyDays:
      final start = today.subtract(const Duration(days: 29));
      return sorted
          .where((ride) => !_startOfDay(ride.date).isBefore(start))
          .toList();
    case HistoryQuickFilter.all:
      return sorted;
  }
}

bool _isWithinCustomRange(DateTime date, DateTimeRange range) {
  final day = _startOfDay(date);
  final start = _startOfDay(range.start);
  final end = _startOfDay(range.end);
  return !day.isBefore(start) && !day.isAfter(end);
}

DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

const Object _sentinel = Object();
