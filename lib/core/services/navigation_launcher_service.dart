library;

import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/driver_ride.dart';
import '../../domain/models/ride_status.dart';

enum DriverNavigationLeg { toPickup, toDestination }

class NavigationTarget {
  const NavigationTarget({
    required this.leg,
    required this.latitude,
    required this.longitude,
    this.label,
  });

  final DriverNavigationLeg leg;
  final double latitude;
  final double longitude;
  final String? label;

  bool get hasValidCoordinates =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      !(latitude == 0 && longitude == 0);
}

class NavigationLauncherService {
  const NavigationLauncherService();

  Future<bool> openGoogleMapsDriving({
    required double lat,
    required double lng,
    String? label,
  }) async {
    final navigationUri = buildGoogleMapsNavigationUri(
      lat: lat,
      lng: lng,
      label: label,
    );
    if (await canLaunch(navigationUri)) {
      return launch(navigationUri);
    }

    final webUri = buildGoogleMapsWebUri(lat: lat, lng: lng, label: label);
    if (await canLaunch(webUri)) {
      return launch(webUri);
    }
    return false;
  }

  Future<bool> canLaunch(Uri uri) => canLaunchUrl(uri);

  Future<bool> launch(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  NavigationTarget resolveDriverTarget(DriverRide ride) {
    final isToPickup =
        ride.status == RideStatus.accepted || ride.status == RideStatus.arrived;
    if (isToPickup) {
      return NavigationTarget(
        leg: DriverNavigationLeg.toPickup,
        latitude: ride.pickupLocation.latitude,
        longitude: ride.pickupLocation.longitude,
        label: ride.pickupAddress,
      );
    }

    return NavigationTarget(
      leg: DriverNavigationLeg.toDestination,
      latitude: ride.destinationLocation.latitude,
      longitude: ride.destinationLocation.longitude,
      label: ride.destinationAddress,
    );
  }

  Uri buildGoogleMapsAppUri({
    required double lat,
    required double lng,
    String? label,
  }) {
    return buildGoogleMapsNavigationUri(lat: lat, lng: lng, label: label);
  }

  Uri buildGoogleMapsNavigationUri({
    required double lat,
    required double lng,
    String? label,
  }) {
    return Uri.parse(
      'google.navigation:q=${_coordinateDestination(lat: lat, lng: lng)}&mode=d',
    );
  }

  Uri buildGoogleMapsWebUri({
    required double lat,
    required double lng,
    String? label,
  }) {
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': _coordinateDestination(lat: lat, lng: lng),
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });
  }

  String _coordinateDestination({required double lat, required double lng}) {
    return '$lat,$lng';
  }
}
