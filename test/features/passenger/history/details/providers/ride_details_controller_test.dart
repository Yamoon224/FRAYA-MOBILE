import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/core/services/places_service.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_categories_provider.dart';
import 'package:fraya_mobile/features/passenger/history/details/providers/ride_details_controller.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';

void main() {
  testWidgets(
    'reorderRide uses ride arrivalPlaceId without external resolution',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          placesServiceProvider.overrideWith((ref) => _FakePlacesService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SizedBox())),
        ),
      );

      var navigateCalls = 0;
      final context = tester.element(find.byType(SizedBox));
      final ride = _buildRide(arrivalPlaceId: 'real_place_id_123');
      container
          .read(selectedCategoryProvider.notifier)
          .select(
            const RideCategory(
              id: 'MAGIC',
              name: 'Magic',
              description: 'Eco',
              price: 2500,
              seats: 4,
              iconAsset: 'assets/images/magic.png',
            ),
          );

      await container
          .read(rideDetailsControllerProvider.notifier)
          .reorderRide(context, ride, onNavigate: () => navigateCalls++);

      final destination = container.read(selectedDestinationProvider);
      expect(navigateCalls, 1);
      expect(destination, isNotNull);
      expect(destination!.placeId, 'real_place_id_123');
      expect(
        container.read(bookingFlowProvider),
        BookingFlowState.routePreview,
      );
      expect(container.read(selectedCategoryProvider), isNull);
      expect(container.read(bookingErrorProvider), isNull);
    },
  );

  testWidgets('reorderRide resolves placeId from autocomplete/details', (
    tester,
  ) async {
    final placesService = _FakePlacesService(
      suggestions: [
        PlaceSuggestion(
          placeId: 'google_place_abc',
          description: 'Aeroport Abidjan',
          mainText: 'Aeroport',
          secondaryText: 'Abidjan',
        ),
      ],
      placeDetails: const PlaceDetails(
        placeId: 'google_place_abc',
        name: 'Aeroport Felix Houphouet-Boigny',
        address: 'Route de l Aeroport, Abidjan',
        latitude: 5.262,
        longitude: -3.946,
      ),
    );
    final container = ProviderContainer(
      overrides: [placesServiceProvider.overrideWith((ref) => placesService)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SizedBox())),
      ),
    );

    final context = tester.element(find.byType(SizedBox));
    final ride = _buildRide(arrivalPlaceId: null);
    await container
        .read(rideDetailsControllerProvider.notifier)
        .reorderRide(context, ride, onNavigate: () {});

    final destination = container.read(selectedDestinationProvider);
    expect(destination, isNotNull);
    expect(destination!.placeId, 'google_place_abc');
    expect(container.read(bookingErrorProvider), isNull);
  });

  testWidgets(
    'reorderRide falls back with empty placeId and raises booking error',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          placesServiceProvider.overrideWith((ref) => _FakePlacesService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SizedBox())),
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      await container
          .read(rideDetailsControllerProvider.notifier)
          .reorderRide(
            context,
            _buildRide(arrivalPlaceId: null),
            onNavigate: () {},
          );
      await tester.pump(const Duration(milliseconds: 350));

      final destination = container.read(selectedDestinationProvider);
      expect(destination, isNotNull);
      expect(destination!.placeId, '');
      expect(container.read(bookingErrorProvider), isNotNull);
    },
  );

  testWidgets('reorderRide anti double-click guard executes once', (
    tester,
  ) async {
    final placesService = _FakePlacesService(
      delay: const Duration(milliseconds: 120),
      suggestions: const [],
    );
    final container = ProviderContainer(
      overrides: [placesServiceProvider.overrideWith((ref) => placesService)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SizedBox())),
      ),
    );

    var navigateCalls = 0;
    final context = tester.element(find.byType(SizedBox));
    final notifier = container.read(rideDetailsControllerProvider.notifier);
    final ride = _buildRide(arrivalPlaceId: null);

    final first = notifier.reorderRide(
      context,
      ride,
      onNavigate: () => navigateCalls++,
    );
    final second = notifier.reorderRide(
      context,
      ride,
      onNavigate: () => navigateCalls++,
    );
    await tester.pump(const Duration(milliseconds: 150));
    await Future.wait([first, second]);
    await tester.pump(const Duration(milliseconds: 350));

    expect(navigateCalls, 1);
  });
}

Ride _buildRide({String? arrivalPlaceId}) {
  return Ride(
    id: 'ride_1',
    departureAddress: 'Cocody, Abidjan',
    arrivalAddress: 'Aeroport, Abidjan',
    departureLat: 5.35,
    departureLng: -3.99,
    arrivalLat: 5.26,
    arrivalLng: -3.94,
    arrivalPlaceId: arrivalPlaceId,
    price: 3000,
    date: DateTime(2026, 5, 20),
    status: RideStatus.completed,
    vehicleRange: 'MAGIC',
  );
}

class _FakePlacesService extends PlacesService {
  _FakePlacesService({
    this.suggestions = const [],
    this.placeDetails,
    this.delay = Duration.zero,
  });

  final List<PlaceSuggestion> suggestions;
  final PlaceDetails? placeDetails;
  final Duration delay;

  @override
  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
    String query, {
    String? sessionToken,
    String language = 'fr',
    String components = 'country:ci',
    double? originLat,
    double? originLng,
    bool bypassCache = false,
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return suggestions;
  }

  @override
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String language = 'fr',
  }) async {
    return placeDetails;
  }
}
