import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/active_ride/ride_rating_sheet.dart';

void main() {
  testWidgets('renders without overflow on narrow screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: RideRatingSheet())),
      ),
    );
    await tester.pump();

    expect(find.byType(IconButton), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the selected rating when tapping the same star again', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: RideRatingSheet())),
      ),
    );

    await tester.tap(find.byType(IconButton).first);
    await tester.pump();
    expect(find.text('Tres mauvais'), findsOneWidget);

    await tester.tap(find.byType(IconButton).first);
    await tester.pump();
    expect(find.text('Tres mauvais'), findsOneWidget);
  });
}
