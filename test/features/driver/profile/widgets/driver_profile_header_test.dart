import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/profile/widgets/driver_profile_header.dart';
import 'package:fraya_mobile/shared/models/user_stats_view_data.dart';

void main() {
  testWidgets('shows neutral stats when rating and rides are missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverProfileHeader(
            name: 'Chauffeur Test',
            stats: UserStatsViewData.empty,
          ),
        ),
      ),
    );

    expect(find.text('--'), findsOneWidget);
    expect(find.text('(-- courses)'), findsOneWidget);
  });

  testWidgets('shows the real vehicle range label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverProfileHeader(
            name: 'Chauffeur Test',
            stats: UserStatsViewData.empty,
            rangeLabel: 'Magic',
          ),
        ),
      ),
    );

    expect(find.text('Magic'), findsOneWidget);
    expect(find.text('Elite'), findsNothing);
  });
}
