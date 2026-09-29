import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_live_metrics_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_route_refresh_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/nearest_driver_eta_provider.dart';
import 'package:fraya_mobile/features/passenger/map/providers/nearby_drivers_provider.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test('nearestDriverEtaMinutes is null when no driver is available', () {
    final container = ProviderContainer(
      overrides: [
        nearbyDriversProvider.overrideWithValue(const <NearbyDriver>[]),
        currentLocationProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(bookingOriginSnapshotProvider.notifier)
        .state = BookingOriginSnapshot(
      latitude: 5,
      longitude: -4,
      capturedAt: DateTime(2026, 7, 10),
    );

    expect(container.read(nearestDriverEtaMinutesProvider), isNull);
  });

  test('nearestDriverEtaMinutes is null when origin is unavailable', () {
    final container = ProviderContainer(
      overrides: [
        nearbyDriversProvider.overrideWithValue([
          NearbyDriver(
            id: 'driver-1',
            location: const LatLng(5.0001, -4),
            bearing: 0,
          ),
        ]),
        currentLocationProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(nearestDriverEtaMinutesProvider), isNull);
  });

  test('nearestDriverEtaMinutes computes a minimum one minute estimate', () {
    final container = ProviderContainer(
      overrides: [
        nearbyDriversProvider.overrideWithValue([
          NearbyDriver(
            id: 'driver-1',
            location: const LatLng(5.0001, -4),
            bearing: 0,
          ),
        ]),
        activeRideLiveMetricsAverageSpeedKmhProvider.overrideWithValue(60),
        currentLocationProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(bookingOriginSnapshotProvider.notifier)
        .state = BookingOriginSnapshot(
      latitude: 5,
      longitude: -4,
      capturedAt: DateTime(2026, 7, 10),
    );

    expect(container.read(nearestDriverEtaMinutesProvider), 1);
  });

  test('nearestDriverEtaMinutes prioritizes pickup over snapshot and GPS', () {
    final container = ProviderContainer(
      overrides: [
        nearbyDriversProvider.overrideWithValue([
          NearbyDriver(
            id: 'driver-1',
            location: const LatLng(5.0001, -4),
            bearing: 0,
          ),
        ]),
        activeRideLiveMetricsAverageSpeedKmhProvider.overrideWithValue(60),
        currentLocationProvider.overrideWith(
          (ref) => Stream.value(_position(latitude: 1, longitude: 1)),
        ),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(selectedPickupProvider.notifier)
        .setPlace(
          const PlaceDetails(
            placeId: 'pickup',
            name: 'Pickup',
            address: 'Pickup',
            latitude: 5,
            longitude: -4,
          ),
        );
    container
        .read(bookingOriginSnapshotProvider.notifier)
        .state = BookingOriginSnapshot(
      latitude: 0,
      longitude: 0,
      capturedAt: DateTime(2026, 7, 10),
    );

    expect(container.read(nearestDriverEtaMinutesProvider), 1);
  });

  test(
    'nearestDriverEtaMinutes falls back to GPS when no snapshot exists',
    () async {
      final container = ProviderContainer(
        overrides: [
          nearbyDriversProvider.overrideWithValue([
            NearbyDriver(
              id: 'driver-1',
              location: const LatLng(2.0001, 3),
              bearing: 0,
            ),
          ]),
          activeRideLiveMetricsAverageSpeedKmhProvider.overrideWithValue(60),
          currentLocationProvider.overrideWith(
            (ref) => Stream.value(_position(latitude: 2, longitude: 3)),
          ),
        ],
      );
      addTearDown(container.dispose);
      final locationSub = container.listen(
        currentLocationProvider,
        (_, _) {},
        weak: false,
      );
      addTearDown(locationSub.close);

      await container.read(currentLocationProvider.future);

      expect(container.read(nearestDriverEtaMinutesProvider), 1);
    },
  );
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
