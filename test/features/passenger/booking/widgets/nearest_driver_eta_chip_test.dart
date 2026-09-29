import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/nearest_driver_eta_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/nearest_driver_eta_chip.dart';

void main() {
  testWidgets('NearestDriverEtaChip renders the estimated minutes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [nearestDriverEtaMinutesProvider.overrideWith((ref) => 4)],
        child: const MaterialApp(home: Scaffold(body: NearestDriverEtaChip())),
      ),
    );

    expect(find.text('~4 min'), findsOneWidget);
  });

  testWidgets('NearestDriverEtaChip is hidden when ETA is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nearestDriverEtaMinutesProvider.overrideWith((ref) => null),
        ],
        child: const MaterialApp(home: Scaffold(body: NearestDriverEtaChip())),
      ),
    );

    expect(find.textContaining('min'), findsNothing);
  });
}
