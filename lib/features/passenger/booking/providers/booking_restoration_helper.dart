import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/active_ride.dart';
import '../../../../core/models/places_models.dart';
import '../../../../core/services/address_formatter_service.dart';
import '../../../../shared/providers/places_provider.dart';

class BookingRestorationHelper {
  static const _addressFormatter = AddressFormatterService();

  static void restoreMapState(WidgetRef ref, ActiveRide ride) {
    if (ride.pickupAddress != null) {
      ref
          .read(selectedPickupProvider.notifier)
          .setPlace(_buildPickupPlace(ride));
    }

    if (ride.destinationAddress != null) {
      ref
          .read(selectedDestinationProvider.notifier)
          .setPlace(_buildDestinationPlace(ride));
    }
  }
}

// Version pour Ref (utilisé dans les Notifiers)
class BookingRestorationRefHelper {
  static void restoreMapState(Ref ref, ActiveRide ride) {
    if (ride.pickupAddress != null) {
      ref
          .read(selectedPickupProvider.notifier)
          .setPlace(_buildPickupPlace(ride));
    }

    if (ride.destinationAddress != null) {
      ref
          .read(selectedDestinationProvider.notifier)
          .setPlace(_buildDestinationPlace(ride));
    }
  }
}

PlaceDetails _buildPickupPlace(ActiveRide ride) {
  final normalizedPickup = BookingRestorationHelper._addressFormatter.normalize(
    ride.pickupAddress!,
  );
  return PlaceDetails(
    placeId: ride.pickupPlaceId ?? '',
    name: BookingRestorationHelper._addressFormatter.primaryLabel(
      normalizedPickup,
      fallback: 'Depart',
    ),
    address: normalizedPickup,
    latitude: ride.pickupLocation?.latitude ?? 0,
    longitude: ride.pickupLocation?.longitude ?? 0,
  );
}

PlaceDetails _buildDestinationPlace(ActiveRide ride) {
  final normalizedDestination = BookingRestorationHelper._addressFormatter
      .normalize(ride.destinationAddress!);
  return PlaceDetails(
    placeId: ride.destinationPlaceId ?? '',
    name: BookingRestorationHelper._addressFormatter.primaryLabel(
      normalizedDestination,
      fallback: 'Destination',
    ),
    address: normalizedDestination,
    latitude:
        ride.destinationLocation?.latitude ?? ride.driverLocation.latitude,
    longitude:
        ride.destinationLocation?.longitude ?? ride.driverLocation.longitude,
  );
}
