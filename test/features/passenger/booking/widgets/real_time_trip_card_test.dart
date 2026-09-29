import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_live_metrics_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/active_ride/real_time_trip_card.dart';

void main() {
  testWidgets('renders live traffic source and metrics values', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RealTimeTripCard(
            remainingTime: '9 min',
            remainingDistance: '2.8 km',
            source: ActiveRideLiveMetricsSource.directions,
          ),
        ),
      ),
    );

    expect(find.text('9 min'), findsOneWidget);
    expect(find.text('2.8 km'), findsOneWidget);
    expect(find.text('Source: trafic live'), findsOneWidget);
  });

  testWidgets('renders without overflow on narrow screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 690));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RealTimeTripCard(
            remainingTime: '25 minutes',
            remainingDistance: '11,4 km',
            source: ActiveRideLiveMetricsSource.directions,
          ),
        ),
      ),
    );

    expect(find.text('11,4 km'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
