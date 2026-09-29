import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/features/passenger/history/providers/history_filter_provider.dart';

void main() {
  test('quick filters limit rides by recency', () {
    final now = DateTime.now();
    final rides = [
      _ride('today', now),
      _ride('week', now.subtract(const Duration(days: 5))),
      _ride('month', now.subtract(const Duration(days: 20))),
      _ride('old', now.subtract(const Duration(days: 45))),
    ];

    final filtered = applyHistoryFilter(
      rides,
      const HistoryFilterState(quickFilter: HistoryQuickFilter.sevenDays),
    );

    expect(filtered.map((ride) => ride.id), ['today', 'week']);
  });

  test('custom range overrides quick filter', () {
    final now = DateTime.now();
    final rides = [
      _ride('today', now),
      _ride('week', now.subtract(const Duration(days: 5))),
      _ride('month', now.subtract(const Duration(days: 20))),
    ];

    final filtered = applyHistoryFilter(
      rides,
      HistoryFilterState(
        quickFilter: HistoryQuickFilter.today,
        customRange: DateTimeRange(
          start: now.subtract(const Duration(days: 21)),
          end: now.subtract(const Duration(days: 19)),
        ),
      ),
    );

    expect(filtered.map((ride) => ride.id), ['month']);
  });
}

Ride _ride(String id, DateTime date) {
  return Ride(
    id: id,
    departureAddress: 'A',
    arrivalAddress: 'B',
    price: 1000,
    date: date,
    status: RideStatus.completed,
    vehicleRange: 'MAGIC',
  );
}
