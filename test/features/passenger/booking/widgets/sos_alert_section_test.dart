import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/active_ride/sos_alert_section.dart';

void main() {
  testWidgets('opens the SOS reason sheet', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SosAlertSection(rideId: 'ride-77')),
        ),
      ),
    );

    await tester.tap(find.textContaining('SOS'));
    await tester.pumpAndSettle();

    expect(find.text("Type d'urgence"), findsOneWidget);
  });
}
