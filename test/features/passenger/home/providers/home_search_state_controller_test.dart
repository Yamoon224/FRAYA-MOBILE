import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/features/passenger/home/providers/home_search_state_controller.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';

void main() {
  test(
    'resetAfterBookingReturn clears places/query and restores destination mode',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final searchSub = container.listen(searchQueryProvider, (_, _) {});
      addTearDown(searchSub.close);

      container
          .read(selectedDestinationProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: 'google_destination',
              name: 'Aeroport',
              address: 'Route de l\'Aeroport',
              latitude: 5.26,
              longitude: -3.94,
            ),
          );
      container
          .read(selectedPickupProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: 'google_pickup',
              name: 'Residence',
              address: 'Rue 12, Cocody',
              latitude: 5.35,
              longitude: -4.02,
            ),
          );
      container
          .read(activeSearchTypeProvider.notifier)
          .setType(SearchType.pickup);
      container.read(searchQueryProvider.notifier).updateQuery('Aeroport');
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(container.read(selectedDestinationProvider), isNotNull);
      expect(container.read(selectedPickupProvider), isNotNull);
      expect(container.read(searchQueryProvider), 'Aeroport');
      expect(container.read(activeSearchTypeProvider), SearchType.pickup);

      container
          .read(homeSearchStateControllerProvider)
          .resetAfterBookingReturn();

      expect(container.read(selectedDestinationProvider), isNull);
      expect(container.read(selectedPickupProvider), isNull);
      expect(container.read(searchQueryProvider), '');
      expect(container.read(activeSearchTypeProvider), SearchType.destination);
    },
  );
}
