import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/services/places_service.dart';
import 'package:fraya_mobile/features/passenger/home/providers/home_destination_intent_controller.dart';
import 'package:fraya_mobile/features/passenger/home/widgets/search/suggestion_result_tile.dart';
import 'package:fraya_mobile/features/passenger/home/widgets/search/suggestions_list.dart';
import 'package:fraya_mobile/shared/providers/favorite_places_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';

void main() {
  testWidgets(
    'search results tap does not throw when sheet is disposed during await',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            placesServiceProvider.overrideWith(
              (ref) => _DelayedPlacesService(
                delay: const Duration(milliseconds: 80),
              ),
            ),
            homeDestinationIntentControllerProvider.overrideWith(
              (ref) => _NoopHomeDestinationIntentController(ref),
            ),
            favoritePlacesListProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SearchResultsList(
                suggestionsAsync: AsyncData([
                  PlaceSuggestion(
                    placeId: 'google_3',
                    description: 'Plateau, Abidjan',
                    mainText: 'Plateau',
                    secondaryText: 'Abidjan',
                  ),
                ]),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Plateau'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 150));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('suggestion tile enriches subtitle after details resolve', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placesServiceProvider.overrideWith(
            (ref) => _DelayedPlacesService(
              delay: const Duration(milliseconds: 80),
              details: const PlaceDetails(
                placeId: 'google_4',
                name: 'Angre 8eme tranche',
                address: 'Angre 8eme tranche, Cocody',
                latitude: 5.39,
                longitude: -3.99,
                localityLabel: 'Angre 8eme tranche, Cocody',
              ),
            ),
          ),
          favoritePlacesListProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SuggestionResultTile(
              place: PlaceSuggestion(
                placeId: 'google_4',
                description: 'Cocody',
                mainText: 'Angre 8eme tranche',
                secondaryText: 'Cocody',
              ),
              searchType: SearchType.destination,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cocody'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 90));
    await tester.pump();

    expect(find.text('Angre 8eme tranche, Cocody'), findsOneWidget);
    expect(find.text('Cocody'), findsNothing);
  });

  testWidgets('suggestion tile uses compact typography and spacing', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoritePlacesListProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SuggestionResultTile(
              place: PlaceSuggestion(
                placeId: '',
                description: 'Angre 8eme tranche, Cocody',
                mainText: 'Une adresse volontairement très longue à Cocody',
                secondaryText: 'Angre 8eme tranche, Cocody',
                distanceMeters: 1250,
              ),
              searchType: SearchType.destination,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    final title = tester.widget<Text>(
      find.text('Une adresse volontairement très longue à Cocody'),
    );
    final subtitle = tester.widget<Text>(
      find.text('Angre 8eme tranche, Cocody'),
    );
    final leading = tester.widget<Icon>(
      find.byIcon(Icons.location_on_outlined),
    );
    final star = tester.widget<Icon>(find.byIcon(Icons.star_outline_rounded));

    expect(tile.dense, isTrue);
    expect(tile.visualDensity, const VisualDensity(vertical: -2));
    expect(tile.contentPadding, const EdgeInsets.only(left: 16, right: 4));
    expect(tile.minVerticalPadding, 4);
    expect(tile.horizontalTitleGap, 10);
    expect(title.style?.fontSize, 13);
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(subtitle.style?.fontSize, 11);
    expect(subtitle.style?.fontWeight, FontWeight.w500);
    expect(leading.size, 20);
    expect(star.size, 20);
    expect(tester.takeException(), isNull);
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

class _DelayedPlacesService extends PlacesService {
  _DelayedPlacesService({
    required this.delay,
    this.details = const PlaceDetails(
      placeId: 'google_3',
      name: 'Plateau',
      address: 'Plateau, Abidjan',
      latitude: 5.32,
      longitude: -4.02,
    ),
  });

  final Duration delay;
  final PlaceDetails details;

  @override
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String language = 'fr',
  }) async {
    await Future<void>.delayed(delay);
    return details;
  }
}
