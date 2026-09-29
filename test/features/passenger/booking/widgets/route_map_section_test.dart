import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/directions_models.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/directions_repository.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/directions_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/route_map_section.dart';
import 'package:fraya_mobile/features/passenger/map/providers/nearby_drivers_provider.dart';
import 'package:fraya_mobile/shared/widgets/map/fraya_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  testWidgets('places non-draggable pickup marker at pickup coordinate', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [nearbyDriversProvider.overrideWithValue(const [])],
        child: MaterialApp(
          home: Scaffold(
            body: RouteMapSection(
              directionsAsync: const AsyncData(null),
              position: _position(latitude: 5.30, longitude: -4.00),
              pickup: _pickup,
              destination: _destination,
              onMapCreated: (_) {},
            ),
          ),
        ),
      ),
    );

    final map = tester.widget<FrayaMap>(find.byType(FrayaMap));
    final origin = _marker(map, 'origin');
    final dest = _marker(map, 'destination');

    expect(origin.position, const LatLng(5.31, -4.01));
    expect(origin.draggable, isFalse);
    expect(dest.position, const LatLng(5.25, -3.93));
    expect(dest.draggable, isFalse);
  });

  testWidgets(
    'renders only the main route when directions include alternatives',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [nearbyDriversProvider.overrideWithValue(const [])],
          child: MaterialApp(
            home: Scaffold(
              body: RouteMapSection(
                directionsAsync: AsyncData(_directionsWithAlternatives),
                position: _position(latitude: 5.30, longitude: -4.00),
                pickup: _pickup,
                destination: _destination,
                onMapCreated: (_) {},
              ),
            ),
          ),
        ),
      );

      final map = tester.widget<FrayaMap>(find.byType(FrayaMap));

      expect(map.polylines, hasLength(1));
      expect(map.polylines.single.polylineId, const PolylineId('route_0'));
      expect(map.polylines.single.width, 6);
    },
  );

  testWidgets('in-progress map shows only driver and destination tracking', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nearbyDriversProvider.overrideWithValue(const []),
          bookingFlowProvider.overrideWithValue(BookingFlowState.inProgress),
          activeRideControllerProvider.overrideWith(
            _InProgressActiveRideController.new,
          ),
          directionsRepositoryProvider.overrideWithValue(
            _FakeDirectionsRepository(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RouteMapSection(
              directionsAsync: const AsyncData(null),
              position: _position(latitude: 5.30, longitude: -4.00),
              pickup: _pickup,
              destination: _destination,
              onMapCreated: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final map = tester.widget<FrayaMap>(find.byType(FrayaMap));
    final markerIds = map.markers.map((marker) => marker.markerId.value);
    expect(markerIds, containsAll(['driver', 'active_ride_destination']));
    expect(markerIds, isNot(contains('origin')));
    expect(markerIds, isNot(contains('active_ride_pickup')));
    expect(map.myLocationEnabled, isFalse);
    expect(map.autoCenterOnUser, isFalse);
    expect(map.polylines.single.polylineId.value, 'active_ride_route');
  });
}

class _InProgressActiveRideController extends ActiveRideController {
  @override
  ActiveRide? build() => _activeRideInProgress;
}

class _FakeDirectionsRepository implements DirectionsRepository {
  @override
  Future<DirectionsResult?> getRouteDirections(
    GetRouteDirectionsParams params,
  ) async {
    return _directionsWithAlternatives;
  }
}

final _directionsWithAlternatives = DirectionsResult(
  routes: [
    _route(distanceValue: 1200, durationValue: 300),
    _route(distanceValue: 900, durationValue: 260),
  ],
);

DirectionsRoute _route({
  required int distanceValue,
  required int durationValue,
}) {
  return DirectionsRoute(
    encodedPolyline: r'_p~iF~ps|U_ulLnnqC_mqNvxq`@',
    distanceText: '${(distanceValue / 1000).toStringAsFixed(1)} km',
    distanceValue: distanceValue,
    durationText: '${(durationValue / 60).ceil()} min',
    durationValue: durationValue,
    arrivalTime: null,
    durationInTrafficValue: null,
    trafficSegments: const [],
    hasTrafficData: false,
  );
}

const _pickup = PlaceDetails(
  placeId: 'pickup',
  name: 'Pickup',
  address: 'Pickup',
  latitude: 5.31,
  longitude: -4.01,
);

const _destination = PlaceDetails(
  placeId: 'destination',
  name: 'Destination',
  address: 'Destination',
  latitude: 5.25,
  longitude: -3.93,
);

const _activeRideInProgress = ActiveRide(
  rideId: 'ride-42',
  driverName: 'Jean',
  driverPhoto: 'assets/images/driver_placeholder.png',
  driverRating: 4.8,
  carModel: 'Toyota',
  carPlate: 'AB-123-CD',
  driverLocation: LatLng(5.29, -3.97),
  pickupLocation: LatLng(5.31, -4.01),
  destinationLocation: LatLng(5.25, -3.93),
  status: RideStatus.inProgress,
  estimatedPrice: 2500,
);

Marker _marker(FrayaMap map, String id) {
  return map.markers.singleWhere((marker) => marker.markerId.value == id);
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
