import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_utils.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/payment_method_provider.dart';

void main() {
  group('BookingFlowUtils.buildRideRequestParams', () {
    test('normalizes pickup and arrival addresses before payload build', () {
      final params = BookingFlowUtils.buildRideRequestParams(
        userId: 12,
        destination: const PlaceDetails(
          placeId: 'place_1',
          name: 'Plateau',
          address: 'Cocody, Riviera Palmeraie',
          latitude: 5.34,
          longitude: -4.01,
        ),
        pickupLat: 5.31,
        pickupLng: -4.03,
        category: const RideCategory(
          id: 'MAGIC',
          name: 'Magic',
          description: 'Economique',
          price: 2200,
          amountReceived: 2000,
          seats: 4,
          iconAsset: 'assets/images/magic.png',
        ),
        manualPickupName: 'Yopougon, Niangon',
        paymentMethod: PaymentMethod.cash,
      );

      expect(params.departureAddress, 'Niangon, Yopougon');
      expect(params.arrivalAddress, 'Riviera Palmeraie, Cocody');
      expect(params.estimatedPrice, 2200);
      expect(params.finalPrice, 2200);
      expect(params.amountReceived, 2000);
      expect(params.stops, isEmpty);
      expect(params.finalDistanceKm, 0);
      expect(params.finalDuration, 0);
      expect(params.passengerComment, '');
    });

    test('falls back gracefully when input addresses are empty', () {
      final params = BookingFlowUtils.buildRideRequestParams(
        userId: 15,
        destination: const PlaceDetails(
          placeId: '',
          name: 'Destination libre',
          address: '',
          latitude: 5.33,
          longitude: -4.02,
        ),
        pickupLat: 5.30,
        pickupLng: -4.00,
        category: const RideCategory(
          id: 'MAGIC',
          name: 'Magic',
          description: 'Economique',
          price: 2200,
          seats: 4,
          iconAsset: 'assets/images/magic.png',
        ),
        manualPickupName: null,
        currentAddress: 'Rue 27, Cocody',
        paymentMethod: PaymentMethod.cash,
      );

      expect(params.departureAddress, 'Rue 27, Cocody');
      expect(params.arrivalAddress, 'Destination libre');
    });
  });
}
