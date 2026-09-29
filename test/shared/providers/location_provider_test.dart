import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/geocoding_service.dart';
import 'package:fraya_mobile/core/services/location_service.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  test(
    'passengerLocationSnapshotProvider reads a single position without opening the realtime stream',
    () async {
      final fakeLocationService = _FakeLocationService()
        ..nextLastKnownPosition = null;
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWith((ref) => fakeLocationService),
        ],
      );
      addTearDown(container.dispose);

      final position = await container.read(
        passengerLocationSnapshotProvider.future,
      );

      expect(position, isNotNull);
      expect(fakeLocationService.lastKnownPositionCallCount, 1);
      expect(fakeLocationService.currentPositionCallCount, 1);
      expect(fakeLocationService.positionStreamCallCount, 0);
    },
  );

  test(
    'passengerLocationSnapshotProvider uses last known position before requesting GPS',
    () async {
      final fakeLocationService = _FakeLocationService();
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWith((ref) => fakeLocationService),
        ],
      );
      addTearDown(container.dispose);

      final position = await container.read(
        passengerLocationSnapshotProvider.future,
      );

      expect(position, fakeLocationService.nextLastKnownPosition);
      expect(fakeLocationService.lastKnownPositionCallCount, 1);
      expect(fakeLocationService.currentPositionCallCount, 0);
      expect(fakeLocationService.positionStreamCallCount, 0);
    },
  );

  test(
    'passenger snapshot address refreshes explicitly via the refresh trigger',
    () async {
      final fakeLocationService = _FakeLocationService()
        ..nextLastKnownPosition = null;
      final fakeGeocodingService = _FakeGeocodingService();
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWith((ref) => fakeLocationService),
          geocodingServiceProvider.overrideWith((ref) => fakeGeocodingService),
        ],
      );
      addTearDown(container.dispose);

      var address = await container.read(passengerUserAddressProvider.future);
      expect(address['formatted'], '5.35,-4.01');

      fakeLocationService.nextPosition = Position(
        longitude: -3.98,
        latitude: 5.42,
        timestamp: DateTime(2026, 6, 24, 12),
        accuracy: 6,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      container
          .read(passengerLocationSnapshotRefreshTriggerProvider.notifier)
          .state++;

      address = await container.read(passengerUserAddressProvider.future);
      expect(address['formatted'], '5.42,-3.98');
      expect(fakeLocationService.lastKnownPositionCallCount, 2);
      expect(fakeLocationService.currentPositionCallCount, 2);
      expect(fakeLocationService.positionStreamCallCount, 0);
    },
  );

  test(
    'passengerLocationReadinessProvider exposes unavailable when no snapshot position exists',
    () async {
      final fakeLocationService = _FakeLocationService()
        ..nextLastKnownPosition = null
        ..nextPosition = null;
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWith((ref) => fakeLocationService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(passengerLocationSnapshotProvider.future);

      expect(
        container.read(passengerLocationReadinessProvider),
        PassengerLocationReadiness.unavailable,
      );
      expect(fakeLocationService.positionStreamCallCount, 0);
    },
  );
}

class _FakeLocationService extends LocationService {
  int currentPositionCallCount = 0;
  int lastKnownPositionCallCount = 0;
  int positionStreamCallCount = 0;
  Position? nextLastKnownPosition = Position(
    longitude: -4.02,
    latitude: 5.36,
    timestamp: DateTime(2026, 6, 24),
    accuracy: 16,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
  Position? nextPosition = Position(
    longitude: -4.01,
    latitude: 5.35,
    timestamp: DateTime(2026, 6, 24),
    accuracy: 8,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  @override
  Future<Position?> getCurrentPosition() async {
    currentPositionCallCount++;
    return nextPosition;
  }

  @override
  Future<Position?> getLastKnownPosition() async {
    lastKnownPositionCallCount++;
    return nextLastKnownPosition;
  }

  @override
  Stream<Position> getPositionStream() {
    positionStreamCallCount++;
    return const Stream<Position>.empty();
  }
}

class _FakeGeocodingService extends GeocodingService {
  @override
  Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
    return <String, String>{
      'commune': 'Cocody',
      'quartier': 'Angre',
      'formatted': '${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}',
    };
  }
}
