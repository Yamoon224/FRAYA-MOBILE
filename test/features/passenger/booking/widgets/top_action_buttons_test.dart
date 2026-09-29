import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/top_action_buttons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  testWidgets('shows live distance instead of hardcoded 100m', (tester) async {
    final ride = ActiveRide.mock.copyWith(
      status: RideStatus.accepted,
      driverLocation: const LatLng(5, -4),
      pickupLocation: const LatLng(5.000405, -4),
    );
    final container = ProviderContainer(
      overrides: [
        activeRideControllerProvider.overrideWithValue(ride),
        bookingFlowProvider.overrideWithValue(BookingFlowState.idle),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: TopActionButtons(onBackPressed: () {})),
        ),
      ),
    );

    expect(find.text('Chauffeur en route • 45 m'), findsOneWidget);
    expect(find.textContaining('100m'), findsNothing);
  });

  testWidgets('shows the estimated driver arrival time bubble', (tester) async {
    final ride = ActiveRide.mock.copyWith(status: RideStatus.accepted);
    final container = ProviderContainer(
      overrides: [
        activeRideControllerProvider.overrideWithValue(ride),
        bookingFlowProvider.overrideWithValue(BookingFlowState.driverAssigned),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: TopActionButtons(arrivalTime: '10:11', onBackPressed: () {}),
          ),
        ),
      ),
    );

    expect(find.text('arrivee a 10:11'), findsOneWidget);
  });

  testWidgets('shows the share button only for arrived and in-progress rides', (
    tester,
  ) async {
    await _pumpButtons(
      tester,
      ActiveRide.mock.copyWith(status: RideStatus.arrived),
    );
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);

    await _pumpButtons(
      tester,
      ActiveRide.mock.copyWith(status: RideStatus.inProgress),
    );
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);

    await _pumpButtons(
      tester,
      ActiveRide.mock.copyWith(status: RideStatus.accepted),
    );
    expect(find.byIcon(Icons.share_outlined), findsNothing);
  });

  testWidgets('hides status bubble for terminal ride statuses', (tester) async {
    await _pumpButtons(
      tester,
      ActiveRide.mock.copyWith(status: RideStatus.completed),
    );
    expect(find.text('Course terminee'), findsNothing);

    await _pumpButtons(
      tester,
      ActiveRide.mock.copyWith(status: RideStatus.cancelled),
    );
    expect(find.text('Course annulee'), findsNothing);
  });

  testWidgets('tapping share shows top snackbar feedback from controller', (
    tester,
  ) async {
    final controller = _TestRideShareController(
      const RideShareFeedback(
        message: 'Partage reussi.',
        type: RideShareFeedbackType.success,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        activeRideControllerProvider.overrideWithValue(
          ActiveRide.mock.copyWith(status: RideStatus.arrived),
        ),
        bookingFlowProvider.overrideWithValue(BookingFlowState.arrived),
        rideShareControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: TopActionButtons(onBackPressed: () {})),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pump();

    expect(controller.callCount, 1);
    expect(find.text('Partage reussi.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}

Future<void> _pumpButtons(WidgetTester tester, ActiveRide ride) async {
  final container = ProviderContainer(
    overrides: [
      activeRideControllerProvider.overrideWithValue(ride),
      bookingFlowProvider.overrideWithValue(BookingFlowState.idle),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(body: TopActionButtons(onBackPressed: () {})),
      ),
    ),
  );
}

class _TestRideShareController extends RideShareController {
  _TestRideShareController(this.feedback);

  final RideShareFeedback feedback;
  int callCount = 0;

  @override
  RideShareState build() => const RideShareState();

  @override
  Future<RideShareFeedback?> shareActiveRide() async {
    callCount++;
    return feedback;
  }
}
