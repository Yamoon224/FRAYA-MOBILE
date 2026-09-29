import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fraya_mobile/core/utils/logger.dart';
import 'package:fraya_mobile/core/services/address_formatter_service.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_categories_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/router/route_names.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import '../widgets/ride_receipt_sheet.dart';

part 'ride_details_controller.g.dart';

@riverpod
class RideDetailsController extends _$RideDetailsController {
  static const _addressFormatter = AddressFormatterService();

  bool _isSubmitting = false;
  static const _fallbackPricingWarning =
      "Destination non resolue completement: affichage des prix de base en attendant une actualisation.";

  @override
  void build() {
    ref.keepAlive();
  }

  Future<void> reorderRide(
    BuildContext context,
    Ride ride, {
    VoidCallback? onNavigate,
  }) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    final pickupNotifier = ref.read(selectedPickupProvider.notifier);
    final destinationNotifier = ref.read(selectedDestinationProvider.notifier);
    final bookingErrorNotifier = ref.read(bookingErrorProvider.notifier);
    try {
      final pickup = _buildPickup(ride);
      final destinationResolution = await _resolveDestination(ride);
      if (!ref.mounted) return;

      pickupNotifier.setPlace(pickup);
      destinationNotifier.setPlace(destinationResolution.destination);

      if (!ref.mounted) return;
      ref.read(bookingFlowProvider.notifier).prepareRoutePreviewForReorder();
      ref
              .read(allowBaseCategoriesForUnpricedDestinationProvider.notifier)
              .state =
          destinationResolution.usedFallbackNoPlaceId;

      if (!context.mounted) return;
      if (onNavigate != null) {
        onNavigate();
      } else {
        context.pushNamed(RouteNames.vehicleSelection);
      }

      if (destinationResolution.usedFallbackNoPlaceId) {
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          bookingErrorNotifier.state = _fallbackPricingWarning;
        });
      }
    } catch (error) {
      AppLogger.instance.error('Reorder ride failed: $error');
      bookingErrorNotifier.state =
          "Impossible de relancer ce trajet pour l'instant.";
    } finally {
      _isSubmitting = false;
    }
  }

  void downloadReceipt(BuildContext context, Ride ride) {
    RideReceiptSheet.show(context, ride);
  }

  void shareRide(Ride ride) {
    final text =
        '''
Course Fraya — ${ride.date.shortDate}
De : ${ride.departureAddress}
À : ${ride.arrivalAddress}
${ride.duration != null ? 'Durée : ${ride.duration}' : ''}
Montant : ${ride.price.toCFA}
Paiement : ${ride.paymentMethod ?? 'Espèces'}
'''
            .trim();

    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Mon trajet Fraya du ${ride.date.shortDate}',
      ),
    );
  }

  PlaceDetails _buildPickup(Ride ride) {
    return PlaceDetails(
      placeId: ride.departurePlaceId ?? '',
      name: _extractPrimaryLabel(ride.departureAddress),
      address: ride.departureAddress,
      latitude: ride.departureLat,
      longitude: ride.departureLng,
    );
  }

  Future<_DestinationResolution> _resolveDestination(Ride ride) async {
    final arrivalPlaceId = ride.arrivalPlaceId?.trim() ?? '';
    if (arrivalPlaceId.isNotEmpty) {
      return _DestinationResolution(
        destination: PlaceDetails(
          placeId: arrivalPlaceId,
          name: _extractPrimaryLabel(ride.arrivalAddress),
          address: ride.arrivalAddress,
          latitude: ride.arrivalLat,
          longitude: ride.arrivalLng,
        ),
        usedFallbackNoPlaceId: false,
      );
    }

    try {
      final placesService = ref.read(placesServiceProvider);
      final suggestions = await placesService.getAutocompleteSuggestions(
        ride.arrivalAddress,
      );
      if (suggestions.isNotEmpty) {
        final placeDetails = await placesService.getPlaceDetails(
          suggestions.first.placeId,
        );
        if (placeDetails != null) {
          return _DestinationResolution(
            destination: PlaceDetails(
              placeId: placeDetails.placeId,
              name: placeDetails.name.isEmpty
                  ? _extractPrimaryLabel(ride.arrivalAddress)
                  : placeDetails.name,
              address: placeDetails.address.isEmpty
                  ? _addressFormatter.normalize(ride.arrivalAddress)
                  : _addressFormatter.normalize(placeDetails.address),
              latitude: placeDetails.latitude,
              longitude: placeDetails.longitude,
            ),
            usedFallbackNoPlaceId: false,
          );
        }
      }
    } catch (error) {
      AppLogger.instance.warning(
        'Reorder destination resolution fallback (places unavailable): $error',
      );
    }

    return _DestinationResolution(
      destination: PlaceDetails(
        placeId: '',
        name: _extractPrimaryLabel(ride.arrivalAddress),
        address: ride.arrivalAddress,
        latitude: ride.arrivalLat,
        longitude: ride.arrivalLng,
      ),
      usedFallbackNoPlaceId: true,
    );
  }

  String _extractPrimaryLabel(String address) {
    return _addressFormatter.primaryLabel(address, fallback: 'Destination');
  }
}

class _DestinationResolution {
  const _DestinationResolution({
    required this.destination,
    required this.usedFallbackNoPlaceId,
  });

  final PlaceDetails destination;
  final bool usedFallbackNoPlaceId;
}
