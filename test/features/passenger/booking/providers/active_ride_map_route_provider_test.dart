import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/directions_models.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/directions_repository.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_map_route_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/directions_dependencies.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test('builds driver-to-pickup route for an accepted ride', () async {
    final directions = _ControlledDirectionsRepository();
    final container = _createContainer(directions);
    addTearDown(container.dispose);

    container
        .read(activeRideControllerProvider.notifier)
        .initialize(_ride(status: RideStatus.accepted));

    final query = container.read(activeRideMapRouteQueryProvider);
    expect(query?.rideId, 'ride-map-42');
    expect(query?.target, ActiveRideMapRouteTarget.pickup);
    expect(query?.origin, const LatLng(5.35, -4.02));
    expect(query?.destination, const LatLng(5.401, -3.95));

    await _waitFor(() => directions.requests.length == 1);
    expect(directions.lastOrigin, const LatLng(5.35, -4.02));
    expect(directions.lastDestination, const LatLng(5.401, -3.95));
    expect(directions.lastIncludeAlternatives, isFalse);
  });

  test('builds driver-to-destination route while ride is in progress', () {
    final directions = _ControlledDirectionsRepository();
    final container = _createContainer(directions);
    addTearDown(container.dispose);

    container
        .read(activeRideControllerProvider.notifier)
        .initialize(_ride(status: RideStatus.inProgress));

    final query = container.read(activeRideMapRouteQueryProvider);
    expect(query?.target, ActiveRideMapRouteTarget.destination);
    expect(query?.origin, const LatLng(5.35, -4.02));
    expect(query?.destination, const LatLng(5.32, -4.01));
  });

  test('returns no query without a valid target coordinate', () {
    final directions = _ControlledDirectionsRepository();
    final container = _createContainer(directions);
    addTearDown(container.dispose);

    container
        .read(activeRideControllerProvider.notifier)
        .initialize(
          _ride(status: RideStatus.inProgress, destinationLocation: null),
        );

    expect(container.read(activeRideMapRouteQueryProvider), isNull);
    expect(directions.requests, isEmpty);
  });

  test('uses the selected destination when the active ride omits it', () {
    final directions = _ControlledDirectionsRepository();
    final container = _createContainer(directions);
    addTearDown(container.dispose);
    container
        .read(selectedDestinationProvider.notifier)
        .setPlace(
          const PlaceDetails(
            placeId: 'destination-1',
            name: 'Plateau',
            address: 'Plateau, Abidjan',
            latitude: 5.33,
            longitude: -4.01,
          ),
        );

    container
        .read(activeRideControllerProvider.notifier)
        .initialize(
          _ride(status: RideStatus.inProgress, destinationLocation: null),
        );

    expect(
      container.read(activeRideMapRouteQueryProvider)?.destination,
      const LatLng(5.33, -4.01),
    );
  });

  test('keeps the last route while refreshing the same target', () async {
    final directions = _ControlledDirectionsRepository();
    final container = _createContainer(directions);
    addTearDown(container.dispose);

    container
        .read(activeRideControllerProvider.notifier)
        .initialize(_ride(status: RideStatus.inProgress));
    await _waitFor(() => directions.requests.length == 1);
    directions.complete(0, _directions('first'));
    await _waitFor(
      () => container.read(activeRideMapRouteProvider).directions != null,
    );

    container
        .read(activeRideControllerProvider.notifier)
        .updateLocation(const LatLng(5.351, -4.019));
    await _waitFor(() => directions.requests.length == 2);

    final refreshing = container.read(activeRideMapRouteProvider);
    expect(refreshing.isRefreshing, isTrue);
    expect(refreshing.directions?.mainRoute.distanceText, 'first');
  });

  test('ignores an obsolete route response', () async {
    final directions = _ControlledDirectionsRepository();
    final container = _createContainer(directions);
    addTearDown(container.dispose);

    container
        .read(activeRideControllerProvider.notifier)
        .initialize(_ride(status: RideStatus.inProgress));
    await _waitFor(() => directions.requests.length == 1);
    directions.complete(0, _directions('initial'));
    await _waitFor(
      () => container.read(activeRideMapRouteProvider).directions != null,
    );

    final notifier = container.read(activeRideControllerProvider.notifier);
    notifier.updateLocation(const LatLng(5.351, -4.019));
    await _waitFor(() => directions.requests.length == 2);
    notifier.updateLocation(const LatLng(5.352, -4.018));
    await _waitFor(() => directions.requests.length == 3);

    directions.complete(1, _directions('obsolete'));
    await Future<void>.delayed(Duration.zero);
    expect(
      container
          .read(activeRideMapRouteProvider)
          .directions
          ?.mainRoute
          .distanceText,
      'initial',
    );

    directions.complete(2, _directions('latest'));
    await _waitFor(
      () =>
          container
              .read(activeRideMapRouteProvider)
              .directions
              ?.mainRoute
              .distanceText ==
          'latest',
    );
  });

  test('clears the pickup route when the ride starts', () async {
    final directions = _ControlledDirectionsRepository();
    final container = _createContainer(directions);
    addTearDown(container.dispose);

    container
        .read(activeRideControllerProvider.notifier)
        .initialize(_ride(status: RideStatus.accepted));
    await _waitFor(() => directions.requests.length == 1);
    directions.complete(0, _directions('pickup route'));
    await _waitFor(
      () => container.read(activeRideMapRouteProvider).directions != null,
    );

    container
        .read(activeRideControllerProvider.notifier)
        .initialize(_ride(status: RideStatus.inProgress));
    await _waitFor(() => directions.requests.length == 2);

    final state = container.read(activeRideMapRouteProvider);
    expect(state.query?.target, ActiveRideMapRouteTarget.destination);
    expect(state.directions, isNull);
    expect(state.isRefreshing, isTrue);
  });
}

ProviderContainer _createContainer(_ControlledDirectionsRepository directions) {
  final container = ProviderContainer(
    overrides: [directionsRepositoryProvider.overrideWithValue(directions)],
  );
  container.listen(
    activeRideMapRouteProvider,
    (_, _) {},
    fireImmediately: true,
  );
  return container;
}

class _ControlledDirectionsRepository implements DirectionsRepository {
  final requests = <Completer<DirectionsResult?>>[];
  LatLng? lastOrigin;
  LatLng? lastDestination;
  bool? lastIncludeAlternatives;

  @override
  Future<DirectionsResult?> getRouteDirections(
    GetRouteDirectionsParams params,
  ) {
    lastOrigin = params.origin;
    lastDestination = params.destination;
    lastIncludeAlternatives = params.includeAlternativeRoutes;
    final request = Completer<DirectionsResult?>();
    requests.add(request);
    return request.future;
  }

  void complete(int index, DirectionsResult result) {
    requests[index].complete(result);
  }
}

DirectionsResult _directions(String distanceText) {
  return DirectionsResult(
    routes: [
      DirectionsRoute(
        encodedPolyline: r'_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        distanceText: distanceText,
        distanceValue: 1000,
        durationText: '3 min',
        durationValue: 180,
        arrivalTime: null,
        durationInTrafficValue: null,
        trafficSegments: const [],
        hasTrafficData: false,
      ),
    ],
  );
}

ActiveRide _ride({
  required RideStatus status,
  LatLng? pickupLocation = const LatLng(5.401, -3.95),
  LatLng? destinationLocation = const LatLng(5.32, -4.01),
}) {
  return ActiveRide(
    rideId: 'ride-map-42',
    driverName: 'Driver',
    driverPhoto: 'assets/images/driver_placeholder.png',
    driverRating: 4.8,
    carModel: 'Toyota',
    carPlate: 'AB-123-CD',
    driverLocation: const LatLng(5.35, -4.02),
    pickupLocation: pickupLocation,
    destinationLocation: destinationLocation,
    status: status,
    estimatedPrice: 2500,
  );
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 40; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition not met before timeout.');
}
