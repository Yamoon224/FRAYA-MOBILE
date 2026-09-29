import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/services/geocoding_service.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/pickup_map_edit_controller.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test('handleMarkerDragEnd resolves address and publishes pickup', () async {
    final fakeGeocoding = _FakeGeocodingService(
      responses: [
        {
          'formatted': 'Rue 1, Cocody',
          'quartier': 'Angre',
          'commune': 'Cocody',
        },
        {
          'formatted': 'Rue 2, Cocody',
          'quartier': 'Riviera',
          'commune': 'Cocody',
        },
      ],
    );
    final container = ProviderContainer(
      overrides: [
        geocodingServiceProvider.overrideWith((ref) => fakeGeocoding),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(pickupMapEditControllerProvider, (_, _) {});
    addTearDown(sub.close);

    final notifier = container.read(pickupMapEditControllerProvider.notifier);
    notifier.enterEditMode(const LatLng(5.1, -4.1));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    notifier.handleMarkerDragStarted();
    notifier.handleMarkerDragEnd(const LatLng(5.2, -4.2));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = container.read(pickupMapEditControllerProvider);
    final pickup = container.read(selectedPickupProvider);
    expect(fakeGeocoding.callCount, 2);
    expect(state.draftLatLng, const LatLng(5.2, -4.2));
    expect(state.draftAddress, 'Rue 2, Cocody');
    expect(state.isResolvingAddress, isFalse);
    expect(pickup, isNotNull);
    expect(pickup!.latitude, closeTo(5.2, 0.000001));
    expect(pickup.longitude, closeTo(-4.2, 0.000001));
    expect(pickup.address, 'Rue 2, Cocody');
  });

  test('stale geocoding response is ignored', () async {
    final first = Completer<Map<String, String>>();
    final second = Completer<Map<String, String>>();
    final fakeGeocoding = _FakeGeocodingService(
      pendingResponses: [first, second],
    );
    final container = ProviderContainer(
      overrides: [
        geocodingServiceProvider.overrideWith((ref) => fakeGeocoding),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(pickupMapEditControllerProvider, (_, _) {});
    addTearDown(sub.close);

    final notifier = container.read(pickupMapEditControllerProvider.notifier);
    notifier.enterEditMode(const LatLng(5.0, -4.0)); // request #1
    notifier.handleMarkerDragStarted();
    notifier.handleMarkerDragEnd(const LatLng(5.3, -4.3)); // request #2

    second.complete({
      'formatted': 'Hotel Etoile, Marcory',
      'quartier': 'Marcory',
      'commune': 'Marcory',
    });
    await Future<void>.delayed(const Duration(milliseconds: 10));

    first.complete({
      'formatted': 'Ancienne adresse',
      'quartier': 'Ancien',
      'commune': 'Cocody',
    });
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = container.read(pickupMapEditControllerProvider);
    final pickup = container.read(selectedPickupProvider);
    expect(state.draftAddress, 'Hotel Etoile, Marcory');
    expect(state.draftName, 'Marcory');
    expect(state.draftLatLng, const LatLng(5.3, -4.3));
    expect(pickup, isNotNull);
    expect(pickup!.latitude, closeTo(5.3, 0.000001));
    expect(pickup.longitude, closeTo(-4.3, 0.000001));
    expect(pickup.address, 'Hotel Etoile, Marcory');
  });

  test('handleMarkerDragEnd publishes manual destination place', () async {
    final fakeGeocoding = _FakeGeocodingService(
      responses: [
        {
          'formatted': 'Boulevard de Marseille, Marcory',
          'quartier': 'Marcory',
          'commune': 'Marcory',
        },
        {
          'formatted': 'Aeroport FHB, Port-Bouet',
          'quartier': 'Aeroport',
          'commune': 'Port-Bouet',
        },
      ],
    );
    final container = ProviderContainer(
      overrides: [
        geocodingServiceProvider.overrideWith((ref) => fakeGeocoding),
      ],
    );
    addTearDown(container.dispose);
    final provider = mapAddressEditControllerProvider(SearchType.destination);
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);

    final notifier = container.read(provider.notifier);
    notifier.enterEditMode(const LatLng(5.28, -3.97));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    notifier.handleMarkerDragStarted();
    notifier.handleMarkerDragEnd(const LatLng(5.25, -3.93));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final destination = container.read(selectedDestinationProvider);
    final state = container.read(provider);
    expect(fakeGeocoding.callCount, 2);
    expect(destination, isNotNull);
    expect(destination!.latitude, closeTo(5.25, 0.000001));
    expect(destination.longitude, closeTo(-3.93, 0.000001));
    expect(destination.address, 'Aeroport FHB, Port-Bouet');
    expect(state.isEditing, isTrue);
    expect(state.isResolvingAddress, isFalse);
  });

  test('enterEditMode alone does not modify selected pickup', () async {
    final fakeGeocoding = _FakeGeocodingService(
      responses: [
        {
          'formatted': 'Nouveau point, Cocody',
          'quartier': 'Riviera',
          'commune': 'Cocody',
        },
      ],
    );
    final container = ProviderContainer(
      overrides: [
        geocodingServiceProvider.overrideWith((ref) => fakeGeocoding),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(pickupMapEditControllerProvider, (_, _) {});
    addTearDown(sub.close);

    container
        .read(selectedPickupProvider.notifier)
        .setPlace(
          const PlaceDetails(
            placeId: 'pickup_existing',
            name: 'Residence',
            address: 'Residence, Cocody',
            latitude: 5.4,
            longitude: -4.1,
          ),
        );

    final notifier = container.read(pickupMapEditControllerProvider.notifier);
    notifier.enterEditMode(const LatLng(5.31, -3.98));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final pickup = container.read(selectedPickupProvider);
    final state = container.read(pickupMapEditControllerProvider);
    expect(fakeGeocoding.callCount, 1);
    expect(pickup, isNotNull);
    expect(pickup!.placeId, 'pickup_existing');
    expect(pickup.latitude, closeTo(5.4, 0.000001));
    expect(pickup.longitude, closeTo(-4.1, 0.000001));
    expect(state.draftLatLng, const LatLng(5.31, -3.98));
    expect(state.draftAddress, 'Nouveau point, Cocody');
  });

  test('panning map while editing does not publish selected pickup', () async {
    final fakeGeocoding = _FakeGeocodingService(
      responses: [
        {
          'formatted': 'Position actuelle, Cocody',
          'quartier': 'Riviera',
          'commune': 'Cocody',
        },
      ],
    );
    final container = ProviderContainer(
      overrides: [
        geocodingServiceProvider.overrideWith((ref) => fakeGeocoding),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(pickupMapEditControllerProvider, (_, _) {});
    addTearDown(sub.close);

    final notifier = container.read(pickupMapEditControllerProvider.notifier);
    const initial = LatLng(5.31, -3.98);
    notifier.enterEditMode(initial);
    notifier.handleCameraMoveStarted();
    notifier.handleCameraIdle(const LatLng(5.35, -4.01));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final pickup = container.read(selectedPickupProvider);
    final state = container.read(pickupMapEditControllerProvider);
    expect(pickup, isNull);
    expect(state.draftLatLng, const LatLng(5.35, -4.01));
    expect(state.isDragging, isFalse);
  });

  test('confirmSelection publishes manual pickup place', () async {
    final fakeGeocoding = _FakeGeocodingService(
      responses: [
        {
          'formatted': 'Rue Siloe Amadou, Koumassi',
          'quartier': 'Koumassi',
          'commune': 'Koumassi',
        },
      ],
    );
    final container = ProviderContainer(
      overrides: [
        geocodingServiceProvider.overrideWith((ref) => fakeGeocoding),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(pickupMapEditControllerProvider, (_, _) {});
    addTearDown(sub.close);

    final notifier = container.read(pickupMapEditControllerProvider.notifier);
    notifier.enterEditMode(const LatLng(5.31, -3.98));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await notifier.confirmSelection();

    final pickup = container.read(selectedPickupProvider);
    final state = container.read(pickupMapEditControllerProvider);
    expect(pickup, isNotNull);
    expect(pickup!.latitude, closeTo(5.31, 0.000001));
    expect(pickup.longitude, closeTo(-3.98, 0.000001));
    expect(pickup.address, 'Rue Siloe Amadou, Koumassi');
    expect(state.isEditing, isFalse);
  });

  test('cancelEditing does not modify selected pickup', () async {
    final fakeGeocoding = _FakeGeocodingService(
      responses: [
        {
          'formatted': 'Rue 10, Cocody',
          'quartier': 'Angre',
          'commune': 'Cocody',
        },
      ],
    );
    final container = ProviderContainer(
      overrides: [
        geocodingServiceProvider.overrideWith((ref) => fakeGeocoding),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(pickupMapEditControllerProvider, (_, _) {});
    addTearDown(sub.close);

    container
        .read(selectedPickupProvider.notifier)
        .setPlace(
          const PlaceDetails(
            placeId: 'pickup_existing',
            name: 'Residence',
            address: 'Residence, Cocody',
            latitude: 5.4,
            longitude: -4.1,
          ),
        );

    final notifier = container.read(pickupMapEditControllerProvider.notifier);
    notifier.enterEditMode(const LatLng(5.35, -4.0));
    notifier.cancelEditing();

    final pickup = container.read(selectedPickupProvider);
    final state = container.read(pickupMapEditControllerProvider);
    expect(pickup, isNotNull);
    expect(pickup!.placeId, 'pickup_existing');
    expect(state.isEditing, isFalse);
  });
}

class _FakeGeocodingService extends GeocodingService {
  _FakeGeocodingService({
    this.responses = const [],
    this.pendingResponses = const [],
  });

  final List<Map<String, String>> responses;
  final List<Completer<Map<String, String>>> pendingResponses;
  int _index = 0;
  int callCount = 0;

  @override
  Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
    callCount++;
    if (_index < pendingResponses.length) {
      return pendingResponses[_index++].future;
    }
    if (_index < responses.length) {
      return responses[_index++];
    }
    return {'formatted': '', 'quartier': '', 'commune': ''};
  }
}
