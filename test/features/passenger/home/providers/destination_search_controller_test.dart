import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/services/places_service.dart';
import 'package:fraya_mobile/features/passenger/home/providers/address_search_sheet_focus_controller.dart';
import 'package:fraya_mobile/features/passenger/home/providers/destination_search_controller.dart';
import 'package:fraya_mobile/features/passenger/home/providers/home_destination_intent_controller.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';

void main() {
  testWidgets(
    'handlePlaceSelection completes when provider is disposed mid-await',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          placesServiceProvider.overrideWith(
            (ref) => _FakePlacesService(
              detailsDelay: const Duration(milliseconds: 80),
              placeDetails: const PlaceDetails(
                placeId: 'google_1',
                name: 'Aeroport',
                address: 'Aeroport Abidjan',
                latitude: 5.26,
                longitude: -3.94,
              ),
            ),
          ),
          homeDestinationIntentControllerProvider.overrideWith(
            (ref) => _NoopHomeDestinationIntentController(ref),
          ),
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
      final future = container
          .read(destinationSearchControllerProvider.notifier)
          .handlePlaceSelection(
            context,
            PlaceSuggestion(
              placeId: 'google_1',
              description: 'Aeroport Abidjan',
              mainText: 'Aeroport',
              secondaryText: 'Abidjan',
            ),
            SearchType.destination,
          );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 120));
      await expectLater(future, completes);
    },
  );

  testWidgets(
    'handleDirectPlaceSelection completes when provider is disposed mid-await',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          placesServiceProvider.overrideWith(
            (ref) => _FakePlacesService(
              suggestionsDelay: const Duration(milliseconds: 80),
              suggestions: [
                PlaceSuggestion(
                  placeId: 'google_2',
                  description: 'Plateau, Abidjan',
                  mainText: 'Plateau',
                  secondaryText: 'Abidjan',
                ),
              ],
              placeDetails: const PlaceDetails(
                placeId: 'google_2',
                name: 'Plateau',
                address: 'Plateau, Abidjan',
                latitude: 5.32,
                longitude: -4.02,
              ),
            ),
          ),
          homeDestinationIntentControllerProvider.overrideWith(
            (ref) => _NoopHomeDestinationIntentController(ref),
          ),
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
      final future = container
          .read(destinationSearchControllerProvider.notifier)
          .handleDirectPlaceSelection(
            context,
            const PlaceDetails(
              placeId: 'landmark_plateau',
              name: 'Plateau',
              address: 'Plateau',
              latitude: 0,
              longitude: 0,
            ),
            SearchType.destination,
          );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 120));
      await expectLater(future, completes);
    },
  );

  testWidgets('manual pickup selection switches to destination focus', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        homeDestinationIntentControllerProvider.overrideWith(
          (ref) => _NoopHomeDestinationIntentController(ref),
        ),
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
        .read(destinationSearchControllerProvider.notifier)
        .handleManualSelection(
          context,
          'Rue 12, Cocody',
          5.34,
          -4.01,
          SearchType.pickup,
        );

    final focusRequest = container.read(
      addressSearchSheetFocusControllerProvider,
    );

    expect(container.read(selectedPickupProvider), isNotNull);
    expect(container.read(activeSearchTypeProvider), SearchType.destination);
    expect(focusRequest, isNotNull);
    expect(focusRequest!.target, SearchType.destination);
  });
}

class _NoopHomeDestinationIntentController
    extends HomeDestinationIntentController {
  _NoopHomeDestinationIntentController(super.ref);

  @override
  Future<void> handleResolvedDestination({
    required BuildContext context,
    required PlaceDetails destination,
    required bool closeSearchSheet,
    bool addToRecent = true,
  }) async {}
}

class _FakePlacesService extends PlacesService {
  _FakePlacesService({
    this.placeDetails,
    this.suggestions = const [],
    this.detailsDelay = Duration.zero,
    this.suggestionsDelay = Duration.zero,
  });

  final PlaceDetails? placeDetails;
  final List<PlaceSuggestion> suggestions;
  final Duration detailsDelay;
  final Duration suggestionsDelay;

  @override
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String language = 'fr',
  }) async {
    if (detailsDelay > Duration.zero) {
      await Future<void>.delayed(detailsDelay);
    }
    return placeDetails;
  }

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
    if (suggestionsDelay > Duration.zero) {
      await Future<void>.delayed(suggestionsDelay);
    }
    return suggestions;
  }
}
