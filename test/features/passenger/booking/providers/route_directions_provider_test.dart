import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/directions_models.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/domain/repositories/directions_repository.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_route_refresh_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/directions_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/route_directions_provider.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test(
    'routeDirections resolves GPS origin once available after subscription',
    () async {
      final locationController = StreamController<Position?>();
      final directionsRepository = _FakeDirectionsRepository();
      final container = ProviderContainer(
        overrides: [
          currentLocationProvider.overrideWith(
            (ref) => locationController.stream,
          ),
          directionsRepositoryProvider.overrideWithValue(directionsRepository),
        ],
      );
      addTearDown(() async {
        await locationController.close();
        container.dispose();
      });
      final locationSub = container.listen(
        currentLocationProvider,
        (_, _) {},
        weak: false,
      );
      addTearDown(locationSub.close);

      container
          .read(selectedDestinationProvider.notifier)
          .setPlace(
            const PlaceDetails(
              placeId: 'google_place_id',
              name: 'Plateau',
              address: 'Plateau, Abidjan',
              latitude: 5.3201,
              longitude: -4.0169,
            ),
          );

      final routeSub = container.listen(
        routeDirectionsProvider,
        (_, _) {},
        weak: false,
      );
      addTearDown(routeSub.close);
      final future = container.read(routeDirectionsProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(directionsRepository.callCount, 0);

      locationController.add(_position(latitude: 5.3472, longitude: -4.0244));

      final result = await future;
      final snapshot = container.read(bookingOriginSnapshotProvider);

      expect(result, isNotNull);
      expect(directionsRepository.callCount, 1);
      expect(directionsRepository.lastOrigin, const LatLng(5.3472, -4.0244));
      expect(
        directionsRepository.lastDestination,
        const LatLng(5.3201, -4.0169),
      );
      expect(directionsRepository.lastIncludeAlternatives, isFalse);
      expect(snapshot, isNotNull);
      expect(snapshot!.latitude, 5.3472);
      expect(snapshot.longitude, -4.0244);
    },
  );
}

class _FakeDirectionsRepository implements DirectionsRepository {
  int callCount = 0;
  LatLng? lastOrigin;
  LatLng? lastDestination;
  bool? lastIncludeAlternatives;

  @override
  Future<DirectionsResult?> getRouteDirections(
    GetRouteDirectionsParams params,
  ) async {
    callCount++;
    lastOrigin = params.origin;
    lastDestination = params.destination;
    lastIncludeAlternatives = params.includeAlternativeRoutes;
    return DirectionsResult(routes: [DirectionsRoute.empty()]);
  }
}

Position _position({required double latitude, required double longitude}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: DateTime.now(),
    accuracy: 1,
    altitude: 1,
    altitudeAccuracy: 1,
    heading: 1,
    headingAccuracy: 1,
    speed: 1,
    speedAccuracy: 1,
  );
}
