import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_home_stats_grid.dart';

void main() {
  testWidgets('renders wallet balance instead of rating in driver stats grid', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: DriverHomeStatsGrid(
              earnings: 5000,
              walletBalance: 12000,
              rideCount: 3,
              onlineHours: 1.5,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Recette'), findsOneWidget);
    expect(find.text('Mon solde'), findsOneWidget);
    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Temps'), findsOneWidget);
    expect(find.text('Note'), findsNothing);
  });
}
