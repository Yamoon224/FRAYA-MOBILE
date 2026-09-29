import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/services/home_navigation_notifier.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_check_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/home/providers/home_destination_intent_controller.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _SearchingFlowContinue extends BookingFlow {
  @override
  BookingFlowState build() => BookingFlowState.searching;

  @override
  Future<void> cancelSearching({String? reason}) async {
    state = BookingFlowState.searching;
  }
}

class _SearchingFlowCancelable extends BookingFlow {
  bool cancelCalled = false;

  @override
  BookingFlowState build() => BookingFlowState.searching;

  @override
  Future<void> cancelSearching({String? reason}) async {
    cancelCalled = true;
    state = BookingFlowState.routePreview;
  }
}

class _AssignedFlow extends BookingFlow {
  @override
  BookingFlowState build() => BookingFlowState.driverAssigned;
}

class _DestinationIntentTrigger extends ConsumerWidget {
  const _DestinationIntentTrigger({required this.destination});

  final PlaceDetails destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        ref
            .read(homeDestinationIntentControllerProvider)
            .handleResolvedDestination(
              context: context,
              destination: destination,
              closeSearchSheet: false,
            );
      },
      child: const Text('trigger'),
    );
  }
}

void main() {
  const destination = PlaceDetails(
    placeId: 'google_dest_1',
    name: 'Aeroport',
    address: 'Route de l\'Aeroport',
    latitude: 5.26,
    longitude: -3.94,
  );

  testWidgets(
    'searching + Continuer keeps current destination and reopens searching',
    (tester) async {
      var eventCount = 0;
      final sub = HomeNavigationNotifier.instance.openVehicleSelectionEvents
          .listen((_) => eventCount++);
      addTearDown(sub.cancel);

      final container = ProviderContainer(
        overrides: [
          bookingFlowProvider.overrideWith(_SearchingFlowContinue.new),
        ],
      );
      addTearDown(container.dispose);
      final flowSub = container.listen(bookingFlowProvider, (_, _) {});
      addTearDown(flowSub.close);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: _DestinationIntentTrigger(destination: destination),
            ),
          ),
        ),
      );

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Recherche en cours'), findsOneWidget);
      _expectAbove(
        tester,
        find.text('Annuler et continuer'),
        find.text('Continuer'),
      );

      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(container.read(selectedDestinationProvider), isNull);
      expect(eventCount, 1);
    },
  );

  testWidgets(
    'searching + Annuler et continuer cancels and applies destination',
    (tester) async {
      final completer = Completer<void>();
      final sub = HomeNavigationNotifier.instance.openVehicleSelectionEvents
          .listen((_) {
            if (!completer.isCompleted) completer.complete();
          });
      addTearDown(sub.cancel);

      final container = ProviderContainer(
        overrides: [
          bookingFlowProvider.overrideWith(_SearchingFlowCancelable.new),
        ],
      );
      addTearDown(container.dispose);
      final flowSub = container.listen(bookingFlowProvider, (_, _) {});
      addTearDown(flowSub.close);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: _DestinationIntentTrigger(destination: destination),
            ),
          ),
        ),
      );

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler et continuer'));
      await tester.pumpAndSettle();

      final notifier = container.read(bookingFlowProvider.notifier);
      if (notifier is _SearchingFlowCancelable) {
        expect(notifier.cancelCalled, isTrue);
      }
      expect(
        container.read(bookingFlowProvider),
        BookingFlowState.routePreview,
      );
      expect(
        container.read(selectedDestinationProvider)?.placeId,
        destination.placeId,
      );
      await expectLater(completer.future, completes);
    },
  );

  testWidgets(
    'active ride blocks destination update and vehicle selection event',
    (tester) async {
      var eventCount = 0;
      final sub = HomeNavigationNotifier.instance.openVehicleSelectionEvents
          .listen((_) => eventCount++);
      addTearDown(sub.cancel);

      final container = ProviderContainer(
        overrides: [
          bookingFlowProvider.overrideWith(_AssignedFlow.new),
          activeRideControllerProvider.overrideWithValue(
            _activeRide(RideStatus.accepted),
          ),
          activeRideCheckProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);
      final flowSub = container.listen(bookingFlowProvider, (_, _) {});
      addTearDown(flowSub.close);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: _DestinationIntentTrigger(destination: destination),
            ),
          ),
        ),
      );

      await tester.tap(find.text('trigger'));
      await tester.pump();

      expect(find.text('Vous avez déjà une course en cours.'), findsOneWidget);
      expect(container.read(selectedDestinationProvider), isNull);
      expect(eventCount, 0);
    },
  );
}

void _expectAbove(WidgetTester tester, Finder top, Finder bottom) {
  expect(tester.getTopLeft(top).dy, lessThan(tester.getTopLeft(bottom).dy));
}

ActiveRide _activeRide(RideStatus status) {
  return ActiveRide(
    rideId: 'ride_active_123',
    driverName: 'Jean',
    driverPhoto: 'assets/images/driver_placeholder.png',
    driverRating: 4.8,
    carModel: 'Toyota Corolla',
    carPlate: 'AA-123-BB',
    pickupAddress: 'Cocody, Angre',
    destinationAddress: 'Plateau, Avenue Chardy',
    driverLocation: const LatLng(5.35, -4.01),
    pickupLocation: const LatLng(5.36, -4.02),
    destinationLocation: const LatLng(5.32, -4.00),
    status: status,
    estimatedPrice: 3000,
  );
}
