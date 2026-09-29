import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/models/places_models.dart';
import '../../../../core/services/address_formatter_service.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/providers/places_provider.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import 'home_destination_intent_controller.dart';

part 'home_controller.g.dart';

@riverpod
class PassengerHome extends _$PassengerHome {
  static const _addressFormatter = AddressFormatterService();

  @override
  void build() {}

  Future<void> selectPlace(BuildContext context, String placeId) async {
    final details = await ref
        .read(placesServiceProvider)
        .getPlaceDetails(placeId);
    if (!context.mounted) return;
    if (details == null) {
      _showError(context);
      return;
    }
    await ref
        .read(homeDestinationIntentControllerProvider)
        .handleResolvedDestination(
          context: context,
          destination: details,
          closeSearchSheet: false,
        );
  }

  Future<void> handleManualSelection(
    BuildContext context,
    String name,
    double lat,
    double lng,
  ) async {
    final details = PlaceDetails(
      placeId:
          'manual_${name.hashCode}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      address: _addressFormatter.normalize(name),
      latitude: lat,
      longitude: lng,
    );
    await ref
        .read(homeDestinationIntentControllerProvider)
        .handleResolvedDestination(
          context: context,
          destination: details,
          closeSearchSheet: false,
        );
  }

  Future<void> selectRecentPlace(
    BuildContext context,
    PlaceDetails place,
  ) async {
    if (!ensurePassengerLocationReady(context)) return;

    await ref
        .read(homeDestinationIntentControllerProvider)
        .handleResolvedDestination(
          context: context,
          destination: place,
          closeSearchSheet: false,
          addToRecent: false,
        );
  }

  bool ensurePassengerLocationReady(BuildContext context) {
    final readiness = ref.read(passengerLocationReadinessProvider);
    if (readiness == PassengerLocationReadiness.ready) return true;

    AppSnackBar.showError(context, passengerLocationBlockingMessage(readiness));
    return false;
  }

  void _showError(BuildContext context) {
    if (!context.mounted) return;
    AppSnackBar.showError(
      context,
      'Impossible de charger les details de cette destination.',
    );
  }
}
