import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_home_incoming_request_bubble.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  testWidgets('expires the visible incoming ride after 30 seconds', (
    tester,
  ) async {
    final expiredRideIds = <String>[];
    final ride = buildDriverRide(id: 'ride-expiring');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverHomeIncomingRequestBubble(
            availableRides: [ride],
            topPadding: 0,
            isBusy: false,
            onAccept: (_) async {},
            onDecline: (_) async {},
            onExpired: (ride) async {
              expiredRideIds.add(ride.rideId);
            },
          ),
        ),
      ),
    );

    expect(find.text('30s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('29s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 29));
    await tester.pump();

    expect(expiredRideIds, ['ride-expiring']);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
