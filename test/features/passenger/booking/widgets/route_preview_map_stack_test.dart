import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/route_preview_map_stack.dart';

void main() {
  testWidgets('reset camera button stays hidden when not requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingFlowProvider.overrideWithValue(BookingFlowState.idle),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RoutePreviewMapStack(
              mapLayer: const SizedBox.expand(),
              directionsAsync: const AsyncData(null),
              selectedRouteIndex: 0,
              onBackPressed: () {},
              flowState: BookingFlowState.idle,
              showBanner: false,
              activeRideStatus: null,
              activeRideArrivedAt: null,
              liveDistanceText: null,
              liveArrivalTimeText: null,
              onCloseBanner: () {},
              showResetCameraButton: false,
              onResetCameraPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('passenger_map_reset_camera_button')),
      findsNothing,
    );
  });

  testWidgets('reset camera button appears and handles tap', (tester) async {
    var pressed = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingFlowProvider.overrideWithValue(
            BookingFlowState.driverAssigned,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RoutePreviewMapStack(
              mapLayer: const SizedBox.expand(),
              directionsAsync: const AsyncData(null),
              selectedRouteIndex: 0,
              onBackPressed: () {},
              flowState: BookingFlowState.driverAssigned,
              showBanner: false,
              activeRideStatus: RideStatus.accepted,
              activeRideArrivedAt: null,
              liveDistanceText: '1.4 km',
              liveArrivalTimeText: '5 min',
              onCloseBanner: () {},
              showResetCameraButton: true,
              onResetCameraPressed: () => pressed++,
            ),
          ),
        ),
      ),
    );

    final button = find.byKey(const Key('passenger_map_reset_camera_button'));
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pump();

    expect(pressed, 1);
  });
}
