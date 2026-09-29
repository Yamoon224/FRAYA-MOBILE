import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/features/passenger/history/details/widgets/ride_summary_card.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets('renders without overflow on narrow screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final ride = Ride(
      id: 'ride-1',
      departureAddress: 'Cocody',
      arrivalAddress: 'Plateau',
      price: 2700,
      date: DateTime(2026, 6, 2, 11, 45),
      status: RideStatus.completed,
      duration: '2h 59min',
      distance: '123.4 km',
      startedAt: DateTime(2026, 6, 2, 11, 14),
      endedAt: DateTime(2026, 6, 2, 11, 45),
      vehicleRange: 'MAGIC',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: RideSummaryCard(ride: ride),
          ),
        ),
      ),
    );

    expect(find.text('Distance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows business date with start and end times', (tester) async {
    final ride = Ride(
      id: 'ride-2',
      departureAddress: 'Cocody',
      arrivalAddress: 'Plateau',
      price: 3100,
      date: DateTime(2026, 6, 2, 11, 45),
      status: RideStatus.completed,
      duration: '23',
      distance: '8.5',
      startedAt: DateTime(2026, 6, 2, 11, 14),
      endedAt: DateTime(2026, 6, 2, 11, 45),
      vehicleRange: 'MAGIC',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: RideSummaryCard(ride: ride),
          ),
        ),
      ),
    );

    expect(find.textContaining('2 juin 2026'), findsOneWidget);
    expect(find.text('11:14'), findsOneWidget);
    expect(find.text('11:45'), findsWidgets);
    expect(find.text('23 min'), findsOneWidget);
    expect(find.text('8.5 km'), findsOneWidget);
  });
}
