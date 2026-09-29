import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_categories_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_price_auto_refresh_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/route_directions_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('timer refreshes pricing while in route preview', (tester) async {
    var pricingCalls = 0;
    final container = ProviderContainer(
      overrides: [
        bookingFlowProvider.overrideWithValue(BookingFlowState.routePreview),
        ridePriceAutoRefreshIntervalProvider.overrideWithValue(
          const Duration(milliseconds: 5),
        ),
        ridePriceAutoRefreshLifecycleStateProvider.overrideWithValue(
          AppLifecycleState.resumed,
        ),
        rideCategoriesProvider.overrideWith((ref) async {
          pricingCalls++;
          return const <RideCategory>[];
        }),
      ],
    );
    _setDestination(container);
    await container.read(rideCategoriesProvider.future);
    pricingCalls = 0;

    final sub = container.listen(
      ridePriceAutoRefreshProvider,
      (_, _) {},
      weak: false,
    );

    await tester.pump(const Duration(milliseconds: 20));

    expect(pricingCalls, greaterThan(0));
    sub.close();
    container.dispose();
  });

  testWidgets('timer does not refresh pricing outside route preview', (
    tester,
  ) async {
    for (final flowState in BookingFlowState.values.where(
      (state) => state != BookingFlowState.routePreview,
    )) {
      var pricingCalls = 0;
      final container = ProviderContainer(
        overrides: [
          bookingFlowProvider.overrideWithValue(flowState),
          ridePriceAutoRefreshIntervalProvider.overrideWithValue(
            const Duration(milliseconds: 5),
          ),
          ridePriceAutoRefreshLifecycleStateProvider.overrideWithValue(
            AppLifecycleState.resumed,
          ),
          rideCategoriesProvider.overrideWith((ref) async {
            pricingCalls++;
            return const <RideCategory>[];
          }),
        ],
      );
      _setDestination(container);
      final sub = container.listen(
        ridePriceAutoRefreshProvider,
        (_, _) {},
        weak: false,
      );

      await tester.pump(const Duration(milliseconds: 20));

      expect(pricingCalls, 0, reason: flowState.name);
      sub.close();
      container.dispose();
    }
  });

  test('refreshNow invalidates pricing without reading directions', () async {
    var pricingCalls = 0;
    var directionsCalls = 0;
    final container = ProviderContainer(
      overrides: [
        bookingFlowProvider.overrideWithValue(BookingFlowState.routePreview),
        ridePriceAutoRefreshLifecycleStateProvider.overrideWithValue(
          AppLifecycleState.resumed,
        ),
        rideCategoriesProvider.overrideWith((ref) async {
          pricingCalls++;
          return const <RideCategory>[];
        }),
        routeDirectionsProvider.overrideWith((ref) async {
          directionsCalls++;
          return null;
        }),
      ],
    );
    addTearDown(container.dispose);
    _setDestination(container);
    await container.read(rideCategoriesProvider.future);
    pricingCalls = 0;

    await container.read(ridePriceAutoRefreshProvider.notifier).refreshNow();

    expect(pricingCalls, 1);
    expect(directionsCalls, 0);
  });
}

void _setDestination(ProviderContainer container) {
  container
      .read(selectedDestinationProvider.notifier)
      .setPlace(
        const PlaceDetails(
          placeId: 'google_destination',
          name: 'Plateau',
          address: 'Plateau',
          latitude: 5.32,
          longitude: -4.02,
        ),
      );
}
