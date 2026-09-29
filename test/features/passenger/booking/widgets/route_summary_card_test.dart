import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/route_summary_card.dart';

void main() {
  testWidgets('RouteSummaryCard triggers edit callbacks on address taps', (
    tester,
  ) async {
    var pickupTapCount = 0;
    var destinationTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteSummaryCard(
            originName: 'Rue 12, Cocody',
            destinationName: 'KFC 8eme tranche',
            distanceText: '4,2 km',
            durationText: '~10 min',
            onOriginTap: () => pickupTapCount++,
            onDestinationTap: () => destinationTapCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Rue 12, Cocody'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KFC 8eme tranche'));
    await tester.pumpAndSettle();

    expect(pickupTapCount, 1);
    expect(destinationTapCount, 1);
  });
}
