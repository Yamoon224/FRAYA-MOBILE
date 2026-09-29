import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/directions_models.dart';
import 'package:fraya_mobile/core/realtime/socket_health_state.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/directions_repository.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_arrival_progress_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_live_metrics_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/directions_dependencies.dart';
import 'package:fraya_mobile/shared/providers/realtime_providers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test('uses backend metrics when socket is offline', () async {
    final directions = _FakeDirectionsRepository();
    final container = ProviderContainer(
      overrides: [directionsRepositoryProvider.overrideWithValue(directions)],
    );
    addTearDown(container.dispose);

    container.read(activeRideLiveMetricsControllerProvider);
    container
        .read(activeRideControllerProvider.notifier)
        .initialize(
          _ride(
            status: RideStatus.inProgress,
            driverLocation: const LatLng(5.35, -4.02),
            estimatedDuration: '12',
            estimatedDistance: '5.5',
          ),
        );
    await Future<void>.delayed(Duration.zero);

    final metrics = container.read(activeRideLiveMetricsControllerProvider);
    expect(metrics.source, ActiveRideLiveMetricsSource.backend);
    expect(metrics.etaText, '12 min');
    expect(metrics.distanceText, '5.5 km');
    expect(directions.callCount, 0);
  });

  test('switches to directions metrics when realtime is connected', () async {
    final directions = _FakeDirectionsRepository(
      route: DirectionsRoute(
        encodedPolyline: '',
        distanceText: '3.8 km',
        distanceValue: 3800,
        durationText: '11 min',
        durationValue: 660,
        arrivalTime: null,
        durationInTrafficValue: null,
        trafficSegments: const [],
        hasTrafficData: false,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        directionsRepositoryProvider.overrideWithValue(directions),
        activeRideLiveMetricsNowProvider.overrideWith(
          (ref) =>
              () => DateTime(2026, 5, 26, 10, 0),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(realtimeHealthStateProvider.notifier).state =
        SocketHealthState.connected;
    container.read(activeRideLiveMetricsControllerProvider);
    container
        .read(activeRideControllerProvider.notifier)
        .initialize(
          _ride(
            status: RideStatus.inProgress,
            driverLocation: const LatLng(5.35, -4.02),
          ),
        );
    await Future<void>.delayed(Duration.zero);

    final metrics = container.read(activeRideLiveMetricsControllerProvider);
    expect(metrics.source, ActiveRideLiveMetricsSource.directions);
    expect(metrics.etaText, '11 min');
    expect(metrics.distanceText, '3.8 km');
    expect(metrics.arrivalTimeText, '10:11');
    expect(directions.callCount, 1);
    expect(directions.lastIncludeAlternatives, isFalse);
  });

  test(
    'respects movement and interval throttling before recalculating directions',
    () async {
      var now = DateTime(2026, 5, 26, 10, 0, 0);
      final directions = _FakeDirectionsRepository(
        route: DirectionsRoute(
          encodedPolyline: '',
          distanceText: '2.4 km',
          distanceValue: 2400,
          durationText: '7 min',
          durationValue: 420,
          arrivalTime: null,
          durationInTrafficValue: null,
          trafficSegments: const [],
          hasTrafficData: false,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          directionsRepositoryProvider.overrideWithValue(directions),
          activeRideLiveMetricsNowProvider.overrideWith(
            (ref) =>
                () => now,
          ),
          activeRideLiveMetricsMinRecomputeIntervalProvider.overrideWith(
            (ref) => const Duration(seconds: 20),
          ),
          activeRideLiveMetricsMinRecomputeDistanceMetersProvider.overrideWith(
            (ref) => 120,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(realtimeHealthStateProvider.notifier).state =
          SocketHealthState.connected;
      container.read(activeRideLiveMetricsControllerProvider);
      container
          .read(activeRideControllerProvider.notifier)
          .initialize(
            _ride(
              status: RideStatus.inProgress,
              driverLocation: const LatLng(5.35, -4.02),
            ),
          );
      await Future<void>.delayed(Duration.zero);
      expect(directions.callCount, 1);

      now = now.add(const Duration(seconds: 5));
      container
          .read(activeRideControllerProvider.notifier)
          .updateLocation(const LatLng(5.3515, -4.02));
      await Future<void>.delayed(Duration.zero);
      expect(directions.callCount, 1);

      now = now.add(const Duration(seconds: 25));
      container
          .read(activeRideControllerProvider.notifier)
          .updateLocation(const LatLng(5.3532, -4.02));
      await Future<void>.delayed(Duration.zero);
      expect(directions.callCount, 2);
    },
  );

  test('falls back to backend metrics when directions lookup fails', () async {
    final directions = _FakeDirectionsRepository(route: null);
    final container = ProviderContainer(
      overrides: [directionsRepositoryProvider.overrideWithValue(directions)],
    );
    addTearDown(container.dispose);

    container.read(realtimeHealthStateProvider.notifier).state =
        SocketHealthState.connected;
    container.read(activeRideLiveMetricsControllerProvider);
    container
        .read(activeRideControllerProvider.notifier)
        .initialize(
          _ride(
            status: RideStatus.inProgress,
            driverLocation: const LatLng(5.35, -4.02),
            estimatedDuration: '10',
            estimatedDistance: '4.7',
          ),
        );
    await Future<void>.delayed(Duration.zero);

    final metrics = container.read(activeRideLiveMetricsControllerProvider);
    expect(metrics.source, ActiveRideLiveMetricsSource.backend);
    expect(metrics.etaText, '10 min');
    expect(metrics.distanceText, '4.7 km');
  });

  test(
    'uses an approximate approach metric when directions lookup fails',
    () async {
      final directions = _FakeDirectionsRepository(route: null);
      final container = ProviderContainer(
        overrides: [
          directionsRepositoryProvider.overrideWithValue(directions),
          activeRideLiveMetricsNowProvider.overrideWith(
            (ref) =>
                () => DateTime(2026, 5, 26, 10, 0),
          ),
          activeRideLiveMetricsAverageSpeedKmhProvider.overrideWith(
            (ref) => 30,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(realtimeHealthStateProvider.notifier).state =
          SocketHealthState.connected;
      container.read(activeRideLiveMetricsControllerProvider);
      container
          .read(activeRideControllerProvider.notifier)
          .initialize(
            _ride(
              status: RideStatus.accepted,
              driverLocation: const LatLng(5.391, -3.95),
            ),
          );
      await Future<void>.delayed(Duration.zero);

      final metrics = container.read(activeRideLiveMetricsControllerProvider);
      expect(metrics.source, ActiveRideLiveMetricsSource.approximate);
      expect(metrics.etaText, '3 min');
      expect(metrics.distanceText, '1.1 km');
      expect(metrics.arrivalTimeText, '10:03');
    },
  );

  test('arrival progress follows driver movement toward pickup', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(activeRideArrivalProgressProvider);
    container
        .read(activeRideControllerProvider.notifier)
        .initialize(
          _ride(
            status: RideStatus.accepted,
            driverLocation: const LatLng(5.391, -3.95),
          ),
        );

    expect(container.read(activeRideArrivalProgressProvider).progress, 0);
    expect(
      container.read(activeRideArrivalProgressProvider).isIndeterminate,
      isFalse,
    );

    container
        .read(activeRideControllerProvider.notifier)
        .updateLocation(const LatLng(5.396, -3.95));

    expect(
      container.read(activeRideArrivalProgressProvider).progress,
      closeTo(0.5, 0.02),
    );

    container
        .read(activeRideControllerProvider.notifier)
        .updateLocation(const LatLng(5.401, -3.95));

    expect(container.read(activeRideArrivalProgressProvider).progress, 1);
  });

  test('arrival progress is indeterminate without pickup coordinates', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(activeRideArrivalProgressProvider);
    container
        .read(activeRideControllerProvider.notifier)
        .initialize(
          _ride(
            status: RideStatus.accepted,
            driverLocation: const LatLng(5.391, -3.95),
            pickupLocation: null,
          ),
        );

    final progress = container.read(activeRideArrivalProgressProvider);
    expect(progress.isIndeterminate, isTrue);
    expect(progress.progress, 0);
  });

  test('arrival progress resets when ride is no longer accepted', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(activeRideArrivalProgressProvider);
    container
        .read(activeRideControllerProvider.notifier)
        .initialize(
          _ride(
            status: RideStatus.accepted,
            driverLocation: const LatLng(5.391, -3.95),
          ),
        );
    container
        .read(activeRideControllerProvider.notifier)
        .updateLocation(const LatLng(5.396, -3.95));

    expect(
      container.read(activeRideArrivalProgressProvider).isIndeterminate,
      isFalse,
    );

    container
        .read(activeRideControllerProvider.notifier)
        .initialize(
          _ride(
            status: RideStatus.arrived,
            driverLocation: const LatLng(5.401, -3.95),
          ),
        );

    final progress = container.read(activeRideArrivalProgressProvider);
    expect(progress.isIndeterminate, isTrue);
    expect(progress.progress, 0);
  });
}

class _FakeDirectionsRepository implements DirectionsRepository {
  _FakeDirectionsRepository({this.route});

  final DirectionsRoute? route;
  int callCount = 0;
  bool? lastIncludeAlternatives;

  @override
  Future<DirectionsResult?> getRouteDirections(
    GetRouteDirectionsParams params,
  ) async {
    callCount++;
    lastIncludeAlternatives = params.includeAlternativeRoutes;
    if (route == null) return null;
    return DirectionsResult(routes: [route!]);
  }
}

ActiveRide _ride({
  required RideStatus status,
  required LatLng driverLocation,
  LatLng? pickupLocation = const LatLng(5.401, -3.95),
  String? estimatedDuration,
  String? estimatedDistance,
}) {
  return ActiveRide(
    rideId: 'ride-42',
    driverName: 'Driver',
    driverPhoto: 'assets/images/driver_placeholder.png',
    driverRating: 4.8,
    carModel: 'Toyota',
    carPlate: 'AB-123-CD',
    driverLocation: driverLocation,
    pickupLocation: pickupLocation,
    destinationLocation: const LatLng(5.32, -4.01),
    status: status,
    estimatedPrice: 2500,
    estimatedDuration: estimatedDuration,
    estimatedDistance: estimatedDistance,
  );
}
