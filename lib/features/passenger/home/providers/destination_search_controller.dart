import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/models/places_models.dart';
import '../../../../core/services/address_formatter_service.dart';
import '../../../../shared/providers/places_provider.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import 'address_search_sheet_focus_controller.dart';
import 'home_destination_intent_controller.dart';

part 'destination_search_controller.g.dart';

@riverpod
class DestinationSearchController extends _$DestinationSearchController {
  static const _addressFormatter = AddressFormatterService();

  @override
  void build() {}

  Future<void> handlePlaceSelection(
    BuildContext context,
    PlaceSuggestion suggestion,
    SearchType searchType,
  ) async {
    if (!ref.mounted || !context.mounted) return;
    if (searchType == SearchType.pickup) {
      await _handlePickupSuggestionSelection(context, suggestion.placeId);
      return;
    }

    final placesService = ref.read(placesServiceProvider);
    final destinationIntentController = ref.read(
      homeDestinationIntentControllerProvider,
    );
    final details = await placesService.getPlaceDetails(suggestion.placeId);
    if (!ref.mounted || !context.mounted) return;
    if (details == null) {
      _showError(context);
      return;
    }

    await destinationIntentController.handleResolvedDestination(
      context: context,
      destination: details,
      closeSearchSheet: true,
    );
  }

  Future<void> handleDirectPlaceSelection(
    BuildContext context,
    PlaceDetails place,
    SearchType searchType,
  ) async {
    if (!ref.mounted || !context.mounted) return;
    final destinationIntentController = ref.read(
      homeDestinationIntentControllerProvider,
    );

    if (searchType == SearchType.pickup) {
      await _handlePickupDirectSelection(context, place);
      return;
    }

    final destination = await _resolveDestinationPlace(context, place);
    if (!ref.mounted || !context.mounted) return;
    if (destination == null) return;

    await destinationIntentController.handleResolvedDestination(
      context: context,
      destination: destination,
      closeSearchSheet: true,
      addToRecent: !destination.placeId.startsWith('landmark_'),
    );
  }

  Future<void> handleManualSelection(
    BuildContext context,
    String name,
    double lat,
    double lng,
    SearchType searchType,
  ) async {
    if (!ref.mounted || !context.mounted) return;
    final details = PlaceDetails(
      placeId: 'manual_${name.hashCode}',
      name: name,
      address: _addressFormatter.normalize(name),
      latitude: lat,
      longitude: lng,
    );

    if (searchType == SearchType.pickup) {
      ref.read(selectedPickupProvider.notifier).setPlace(details);
      ref.read(searchQueryProvider.notifier).clear();
      ref
          .read(activeSearchTypeProvider.notifier)
          .setType(SearchType.destination);
      ref
          .read(addressSearchSheetFocusControllerProvider.notifier)
          .requestFocus(SearchType.destination);
      return;
    }

    await ref
        .read(homeDestinationIntentControllerProvider)
        .handleResolvedDestination(
          context: context,
          destination: details,
          closeSearchSheet: true,
        );
  }

  Future<void> _handlePickupSuggestionSelection(
    BuildContext context,
    String placeId,
  ) async {
    final success = await ref
        .read(selectedPickupProvider.notifier)
        .selectPlace(placeId);
    if (!ref.mounted || !context.mounted) return;
    if (!success) {
      _showError(context);
      return;
    }
    ref.read(searchQueryProvider.notifier).clear();
    ref.read(activeSearchTypeProvider.notifier).setType(SearchType.destination);
    ref
        .read(addressSearchSheetFocusControllerProvider.notifier)
        .requestFocus(SearchType.destination);
  }

  Future<void> _handlePickupDirectSelection(
    BuildContext context,
    PlaceDetails place,
  ) async {
    if (!ref.mounted) return;
    if (!place.placeId.startsWith('landmark_') || place.hasValidCoordinates) {
      ref.read(selectedPickupProvider.notifier).setPlace(place);
      ref.read(searchQueryProvider.notifier).clear();
      ref
          .read(activeSearchTypeProvider.notifier)
          .setType(SearchType.destination);
      ref
          .read(addressSearchSheetFocusControllerProvider.notifier)
          .requestFocus(SearchType.destination);
      return;
    }

    final suggestions = await ref
        .read(placesServiceProvider)
        .getAutocompleteSuggestions(place.name);
    if (!ref.mounted || !context.mounted) return;
    if (suggestions.isEmpty) {
      ref.read(selectedPickupProvider.notifier).setPlace(place);
      ref.read(searchQueryProvider.notifier).clear();
      ref
          .read(activeSearchTypeProvider.notifier)
          .setType(SearchType.destination);
      ref
          .read(addressSearchSheetFocusControllerProvider.notifier)
          .requestFocus(SearchType.destination);
      return;
    }

    final success = await ref
        .read(selectedPickupProvider.notifier)
        .selectPlace(suggestions.first.placeId);
    if (!ref.mounted || !context.mounted) return;
    if (!success) {
      _showError(context);
      return;
    }
    ref.read(searchQueryProvider.notifier).clear();
    ref.read(activeSearchTypeProvider.notifier).setType(SearchType.destination);
    ref
        .read(addressSearchSheetFocusControllerProvider.notifier)
        .requestFocus(SearchType.destination);
  }

  Future<PlaceDetails?> _resolveDestinationPlace(
    BuildContext context,
    PlaceDetails place,
  ) async {
    if (!ref.mounted) return null;
    if (!place.placeId.startsWith('landmark_') || place.hasValidCoordinates) {
      return place;
    }

    final service = ref.read(placesServiceProvider);
    final suggestions = await service.getAutocompleteSuggestions(place.name);
    if (!ref.mounted || !context.mounted) return null;
    if (suggestions.isEmpty) {
      return place;
    }

    final details = await service.getPlaceDetails(suggestions.first.placeId);
    if (!ref.mounted || !context.mounted) return null;
    if (details == null) {
      _showError(context);
      return null;
    }
    return details;
  }

  void _showError(BuildContext context) {
    if (!ref.mounted || !context.mounted) return;
    AppSnackBar.showError(
      context,
      'Impossible de charger les details de ce lieu.',
    );
  }
}
