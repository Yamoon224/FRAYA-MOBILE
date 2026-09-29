import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/payment_method_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/active_ride_sheet.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/route_preview_bottom_sheet.dart';
import 'package:fraya_mobile/features/passenger/map/providers/nearby_drivers_provider.dart';
import 'package:fraya_mobile/shared/widgets/confirmation_action_column.dart';

void main() {
  testWidgets('keeps active ride bottom sheet at a fixed height', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nearbyDriversProvider.overrideWithValue(<NearbyDriver>[])],
        child: MaterialApp(
          home: Scaffold(
            body: RoutePreviewBottomSheet(
              controller: DraggableScrollableController(),
              flowState: BookingFlowState.arrived,
              activeRideStatus: null,

              directionsAsync: const AsyncData(null),
              destination: null,
              categories: const AsyncLoading(),
              selectedCategory: null,
              selectedPaymentMethod: PaymentMethod.cash,
              onCategorySelected: (_) {},
              onPaymentMethodSelected: (_) {},
              onRefreshRoutePricing: () async {},
              onRefreshRideStatus: () async {},
              onEditPickup: () {},
              onEditDestination: () {},
              onConfirmBooking: () {},
            ),
          ),
        ),
      ),
    );

    final sheet = tester.widget<DraggableScrollableSheet>(
      find.byType(DraggableScrollableSheet),
    );
    expect(sheet.initialChildSize, 0.46);
    expect(sheet.minChildSize, 0.46);
    expect(sheet.maxChildSize, 0.46);
    expect(sheet.snap, isFalse);
  });

  testWidgets(
    'searching driver sheet hugs content instead of using a draggable height',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RoutePreviewBottomSheet(
                controller: DraggableScrollableController(),
                flowState: BookingFlowState.searching,
                activeRideStatus: null,

                directionsAsync: const AsyncData(null),
                destination: null,
                categories: const AsyncLoading(),
                selectedCategory: null,
                selectedPaymentMethod: PaymentMethod.cash,
                onCategorySelected: (_) {},
                onPaymentMethodSelected: (_) {},
                onRefreshRoutePricing: () async {},
                onRefreshRideStatus: () async {},
                onEditPickup: () {},
                onEditDestination: () {},
                onConfirmBooking: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Recherche en cours...'), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
    },
  );

  testWidgets('completed flow no longer renders the active ride sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nearbyDriversProvider.overrideWithValue(<NearbyDriver>[])],
        child: MaterialApp(
          home: Scaffold(
            body: RoutePreviewBottomSheet(
              controller: DraggableScrollableController(),
              flowState: BookingFlowState.completed,
              activeRideStatus: null,
              directionsAsync: const AsyncData(null),
              destination: null,
              categories: const AsyncLoading(),
              selectedCategory: null,
              selectedPaymentMethod: PaymentMethod.cash,
              onCategorySelected: (_) {},
              onPaymentMethodSelected: (_) {},
              onRefreshRoutePricing: () async {},
              onRefreshRideStatus: () async {},
              onEditPickup: () {},
              onEditDestination: () {},
              onConfirmBooking: () {},
            ),
          ),
        ),
      ),
    );

    final sheet = tester.widget<DraggableScrollableSheet>(
      find.byType(DraggableScrollableSheet),
    );
    expect(sheet.initialChildSize, 0.35);
    expect(sheet.snap, isTrue);
    expect(find.byType(ActiveRideSheet), findsNothing);
  });

  testWidgets('route preview hides refresh button while keeping pull refresh', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var refreshCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nearbyDriversProvider.overrideWithValue(<NearbyDriver>[])],
        child: MaterialApp(
          home: Scaffold(
            body: RoutePreviewBottomSheet(
              controller: DraggableScrollableController(),
              flowState: BookingFlowState.routePreview,
              activeRideStatus: null,
              directionsAsync: const AsyncData(null),
              destination: const PlaceDetails(
                placeId: 'google_destination',
                name: 'Plateau',
                address: 'Plateau',
                latitude: 5.32,
                longitude: -4.02,
              ),
              categories: const AsyncLoading(),
              selectedCategory: null,
              selectedPaymentMethod: PaymentMethod.cash,
              onCategorySelected: (_) {},
              onPaymentMethodSelected: (_) {},
              onRefreshRoutePricing: () async => refreshCalls++,
              onRefreshRideStatus: () async {},
              onEditPickup: () {},
              onEditDestination: () {},
              onConfirmBooking: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Actualiser trajet/prix'), findsNothing);

    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();

    expect(refreshCalls, 1);
  });

  testWidgets(
    'searching driver cancellation asks confirmation before cancelling',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      _CapturingBookingFlow.resetCounters();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingFlowProvider.overrideWith(_CapturingBookingFlow.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RoutePreviewBottomSheet(
                controller: DraggableScrollableController(),
                flowState: BookingFlowState.searching,
                activeRideStatus: null,

                directionsAsync: const AsyncData(null),
                destination: null,
                categories: const AsyncData([]),
                selectedCategory: null,
                selectedPaymentMethod: PaymentMethod.cash,
                onCategorySelected: (_) {},
                onPaymentMethodSelected: (_) {},
                onRefreshRoutePricing: () async {},
                onRefreshRideStatus: () async {},
                onEditPickup: () {},
                onEditDestination: () {},
                onConfirmBooking: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.ensureVisible(find.text('Annuler', skipOffstage: false));
      await tester.pump();
      await tester.tap(find.text('Annuler', skipOffstage: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Raison d\'annulation'), findsNothing);
      expect(find.text('Annuler la recherche ?'), findsOneWidget);
      expect(find.byType(ConfirmationActionColumn), findsOneWidget);
      expect(find.textContaining('Plus de 3 annulations'), findsOneWidget);
      _expectAbove(
        tester,
        find.text('Oui, annuler'),
        find.text('Continuer la recherche'),
      );

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Continuer la recherche'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(_CapturingBookingFlow.cancelCalls, 0);

      await tester.tap(find.text('Annuler', skipOffstage: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(FilledButton, 'Oui, annuler'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(_CapturingBookingFlow.cancelCalls, 1);
      expect(
        _CapturingBookingFlow.lastCancelReason,
        'Recherche annulée par le passager',
      );
    },
  );
}

class _CapturingBookingFlow extends BookingFlow {
  static int cancelCalls = 0;
  static String? lastCancelReason;

  static void resetCounters() {
    cancelCalls = 0;
    lastCancelReason = null;
  }

  @override
  BookingFlowState build() => BookingFlowState.searching;

  @override
  Future<void> cancelSearching({String? reason}) async {
    cancelCalls++;
    lastCancelReason = reason;
  }
}

void _expectAbove(WidgetTester tester, Finder top, Finder bottom) {
  expect(tester.getTopLeft(top).dy, lessThan(tester.getTopLeft(bottom).dy));
}
