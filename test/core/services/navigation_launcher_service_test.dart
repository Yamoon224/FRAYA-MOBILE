import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/navigation_launcher_service.dart';
import 'package:fraya_mobile/domain/models/driver_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('NavigationLauncherService.resolveDriverTarget', () {
    test('maps accepted and arrived rides to pickup coordinates', () {
      final service = const NavigationLauncherService();
      final acceptedTarget = service.resolveDriverTarget(
        _ride(status: RideStatus.accepted),
      );
      final arrivedTarget = service.resolveDriverTarget(
        _ride(status: RideStatus.arrived),
      );

      expect(acceptedTarget.leg, DriverNavigationLeg.toPickup);
      expect(acceptedTarget.latitude, 5.404);
      expect(acceptedTarget.longitude, -3.945);
      expect(arrivedTarget.leg, DriverNavigationLeg.toPickup);
    });

    test('maps in-progress rides to destination coordinates', () {
      final service = const NavigationLauncherService();
      final target = service.resolveDriverTarget(
        _ride(status: RideStatus.inProgress),
      );

      expect(target.leg, DriverNavigationLeg.toDestination);
      expect(target.latitude, 5.312);
      expect(target.longitude, -4.03);
    });
  });

  test('buildGoogleMapsNavigationUri starts turn-by-turn navigation', () {
    final service = const NavigationLauncherService();
    final navigationUri = service.buildGoogleMapsNavigationUri(
      lat: 5.312,
      lng: -4.03,
    );

    expect(navigationUri.toString(), 'google.navigation:q=5.312,-4.03&mode=d');
  });

  test('buildGoogleMapsWebUri asks Maps to launch navigation', () {
    final service = const NavigationLauncherService();
    final webUri = service.buildGoogleMapsWebUri(lat: 5.312, lng: -4.03);

    expect(webUri.host, 'www.google.com');
    expect(webUri.path, '/maps/dir/');
    expect(webUri.queryParameters['api'], '1');
    expect(webUri.queryParameters['destination'], '5.312,-4.03');
    expect(webUri.queryParameters['travelmode'], 'driving');
    expect(webUri.queryParameters['dir_action'], 'navigate');
  });

  test('navigation URIs use coordinates even when a label is provided', () {
    final service = const NavigationLauncherService();
    final navigationUri = service.buildGoogleMapsNavigationUri(
      lat: 5.312,
      lng: -4.03,
      label: 'Avenue Chardy, Plateau, Abidjan',
    );
    final webUri = service.buildGoogleMapsWebUri(
      lat: 5.312,
      lng: -4.03,
      label: 'Avenue Chardy, Plateau, Abidjan',
    );

    expect(navigationUri.toString(), 'google.navigation:q=5.312,-4.03&mode=d');
    expect(webUri.queryParameters['destination'], '5.312,-4.03');
  });

  test('openGoogleMapsDriving launches navigation URI first', () async {
    final service = _FakeNavigationLauncherService(
      navigationCanLaunch: true,
      webCanLaunch: true,
      launchResult: true,
    );

    final opened = await service.openGoogleMapsDriving(lat: 5.35, lng: -4.02);

    expect(opened, isTrue);
    expect(service.launches.length, 1);
    expect(service.launches.first.scheme, 'google.navigation');
  });

  test(
    'falls back from navigation URI to web URI when Google Maps navigation is unavailable',
    () async {
      final service = _FakeNavigationLauncherService(
        navigationCanLaunch: false,
        webCanLaunch: true,
        launchResult: true,
      );

      final opened = await service.openGoogleMapsDriving(lat: 5.35, lng: -4.02);

      expect(opened, isTrue);
      expect(service.launches.length, 1);
      expect(service.launches.first.host, 'www.google.com');
    },
  );
}

class _FakeNavigationLauncherService extends NavigationLauncherService {
  _FakeNavigationLauncherService({
    required this.navigationCanLaunch,
    required this.webCanLaunch,
    required this.launchResult,
  });

  final bool navigationCanLaunch;
  final bool webCanLaunch;
  final bool launchResult;
  final List<Uri> launches = <Uri>[];

  @override
  Future<bool> canLaunch(Uri uri) async {
    if (uri.scheme == 'google.navigation') return navigationCanLaunch;
    return webCanLaunch;
  }

  @override
  Future<bool> launch(Uri uri) async {
    launches.add(uri);
    return launchResult;
  }
}

DriverRide _ride({required RideStatus status}) {
  return DriverRide(
    rideId: 'ride-1',
    status: status,
    passengerName: 'Test Passenger',
    pickupAddress: 'Cocody',
    destinationAddress: 'Plateau',
    pickupLocation: const LatLng(5.404, -3.945),
    destinationLocation: const LatLng(5.312, -4.03),
    requestedRange: 'MAGIC',
    estimatedPrice: 2000,
  );
}
