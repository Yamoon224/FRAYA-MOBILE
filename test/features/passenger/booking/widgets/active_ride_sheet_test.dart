import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/active_ride_sheet.dart';

void main() {
  testWidgets('shows cancellation while driver is assigned', (tester) async {
    final container = _containerWithRide(RideStatus.accepted);
    addTearDown(container.dispose);

    await _pumpSheet(tester, container);

    expect(find.text('Annuler la course'), findsOneWidget);
  });

  testWidgets('hides cancellation once driver has arrived', (tester) async {
    final container = _containerWithRide(RideStatus.arrived);
    addTearDown(container.dispose);

    await _pumpSheet(tester, container);

    expect(find.text('Annuler la course'), findsNothing);
  });
}

ProviderContainer _containerWithRide(RideStatus status) {
  final ride = ActiveRide.mock.copyWith(
    status: status,
    driverPhoto: 'assets/images/driver_placeholder.png',
  );
  return ProviderContainer(
    overrides: [activeRideControllerProvider.overrideWithValue(ride)],
  );
}

Future<void> _pumpSheet(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: ActiveRideSheet())),
    ),
  );
  await tester.pump();
}
