import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/directions_models.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/domain/repositories/directions_repository.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/directions_dependencies.dart';
import 'package:fraya_mobile/features/passenger/history/details/providers/ride_details_directions_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test(
    'rideDetailsDirectionsProvider requests routed polyline from service',
    () async {
      final directionsRepository = _FakeDirectionsRepository();
      final container = ProviderContainer(
        overrides: [
          directionsRepositoryProvider.overrideWithValue(directionsRepository),
        ],
      );
      addTearDown(container.dispose);

      final ride = Ride(
        id: 'ride_1',
        departureAddress: 'Cocody',
        arrivalAddress: 'Aeroport',
        departureLat: 5.3510,
        departureLng: -3.9976,
        arrivalLat: 5.2622,
        arrivalLng: -3.9473,
        price: 3000,
        date: DateTime(2026, 5, 20),
        status: RideStatus.completed,
        vehicleRange: 'MAGIC',
      );

      final result = await container.read(
        rideDetailsDirectionsProvider(ride).future,
      );

      expect(result, isNotNull);
      expect(directionsRepository.callCount, 1);
      expect(directionsRepository.lastOrigin, const LatLng(5.351, -3.9976));
      expect(
        directionsRepository.lastDestination,
        const LatLng(5.2622, -3.9473),
      );
      expect(directionsRepository.lastIncludeAlternatives, isFalse);
      expect(result!.mainRoute.getPolylinePoints(), isNotEmpty);
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
    return DirectionsResult(
      routes: const [
        DirectionsRoute(
          encodedPolyline: 'o~um@_m~v@fAvB`@xA',
          distanceText: '1 km',
          distanceValue: 1000,
          durationText: '5 min',
          durationValue: 300,
          arrivalTime: null,
          durationInTrafficValue: null,
          trafficSegments: [],
          hasTrafficData: false,
        ),
      ],
    );
  }
}
