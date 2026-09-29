import 'package:fraya_mobile/domain/repositories/booking_repository.dart';

import '../../../../core/models/directions_models.dart';
import '../../../../core/models/places_models.dart';
import '../../../../core/models/ride_category.dart';
import '../../../../core/services/address_formatter_service.dart';
import 'payment_method_provider.dart';

class BookingFlowUtils {
  static const _addressFormatter = AddressFormatterService();

  static String durationInTrafficForApi(DirectionsRoute? route) {
    if (route == null) return '0';
    return (route.durationInTrafficValue != null)
        ? (route.durationInTrafficValue! / 60).ceil().toString()
        : route.durationMinutes.toString();
  }

  static String trafficPercentageForApi(DirectionsRoute? route) {
    if (route == null ||
        route.durationValue <= 0 ||
        route.durationInTrafficValue == null) {
      return '0';
    }
    final extra = route.durationInTrafficValue! - route.durationValue;
    return (extra <= 0)
        ? '0'
        : ((extra / route.durationValue) * 100).ceil().clamp(0, 100).toString();
  }

  static String toUserMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Bad state: ')) {
      return raw.substring('Bad state: '.length).trim();
    }
    return raw.isNotEmpty
        ? raw
        : "Une erreur est survenue lors de la recherche d'un chauffeur.";
  }

  static int? parseUserId(Map<String, dynamic> userData) {
    final id = userData['id'] ?? userData['userId'] ?? userData['sub'];
    if (id is num) return id.toInt();
    if (id is String) return int.tryParse(id);
    return null;
  }

  static RequestRideParams buildRideRequestParams({
    required int userId,
    required PlaceDetails destination,
    required double pickupLat,
    required double pickupLng,
    required RideCategory category,
    String? manualPickupName,
    String? currentAddress,
    required PaymentMethod paymentMethod,
    DirectionsRoute? activeRoute,
  }) {
    final normalizedPickup = _addressFormatter.normalize(
      manualPickupName ?? '',
    );
    final normalizedCurrentAddress = _addressFormatter.normalize(
      currentAddress ?? '',
    );
    final normalizedArrival = _addressFormatter.normalize(destination.address);
    final fallbackArrivalFromName = _addressFormatter.normalize(
      destination.name,
    );
    final fallbackPickupAddress = _resolvePickupFallback(
      normalizedCurrentAddress: normalizedCurrentAddress,
      rawCurrentAddress: currentAddress ?? '',
    );

    return RequestRideParams(
      userId: userId,
      requestedRange: category.id,
      departureAddress: normalizedPickup.isNotEmpty
          ? normalizedPickup
          : fallbackPickupAddress,
      latDeparture: pickupLat,
      longDeparture: pickupLng,
      arrivalAddress: normalizedArrival.isNotEmpty
          ? normalizedArrival
          : (fallbackArrivalFromName.isNotEmpty
                ? fallbackArrivalFromName
                : destination.name),
      arrivalLat: destination.latitude,
      arrivalLong: destination.longitude,
      arrivalPlaceId: destination.placeId,
      estimatedDistance: activeRoute?.distanceKm ?? 0.0,
      estimatedDuration: activeRoute?.durationMinutes ?? 0,
      estimatedPrice: category.price,
      amountReceived: category.amountReceived ?? category.price,
      finalPrice: category.price,
      durationInTraffic: durationInTrafficForApi(activeRoute),
      trafficPercentage: trafficPercentageForApi(activeRoute),
      paymentMethod: paymentMethod.apiValue,
    );
  }

  static String _resolvePickupFallback({
    required String normalizedCurrentAddress,
    required String rawCurrentAddress,
  }) {
    if (normalizedCurrentAddress.isNotEmpty &&
        !_isTransientLabel(normalizedCurrentAddress)) {
      return normalizedCurrentAddress;
    }
    final raw = rawCurrentAddress.trim();
    if (raw.isNotEmpty && !_isTransientLabel(raw)) {
      return raw;
    }
    return 'Position actuelle';
  }

  static bool _isTransientLabel(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'ma position' ||
        normalized == 'recherche...' ||
        normalized == 'erreur adresse' ||
        normalized == 'position inconnue' ||
        normalized == 'position actuelle';
  }
}
