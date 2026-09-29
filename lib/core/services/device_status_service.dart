library;

import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../../shared/models/device_status_snapshot.dart';
import 'api_availability_guard.dart';

enum DeviceLocationStatus {
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

enum DeviceInternetStatus { online, noInternet, probableAirplaneMode }

class DeviceStatusService {
  DeviceStatusService({
    Connectivity? connectivity,
    Future<List<InternetAddress>> Function(String host)? dnsLookup,
    Future<bool> Function()? isLocationServiceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<List<ConnectivityResult>> Function()? checkConnectivity,
    Stream<List<ConnectivityResult>>? connectivityChanges,
    Future<ApiAvailabilityState> Function()? checkApiAvailability,
    int serverFailureThreshold = 2,
  }) : _dnsLookup = dnsLookup ?? InternetAddress.lookup,
       _isLocationServiceEnabled =
           isLocationServiceEnabled ?? Geolocator.isLocationServiceEnabled,
       _checkPermission = checkPermission ?? Geolocator.checkPermission,
       _checkConnectivity =
           checkConnectivity ??
           (connectivity ?? Connectivity()).checkConnectivity,
       _connectivityChanges =
           connectivityChanges ??
           (connectivity ?? Connectivity()).onConnectivityChanged,
       _checkApiAvailability = checkApiAvailability,
       _serverFailureThreshold = serverFailureThreshold;

  final Future<List<InternetAddress>> Function(String host) _dnsLookup;
  final Future<bool> Function() _isLocationServiceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<List<ConnectivityResult>> Function() _checkConnectivity;
  final Stream<List<ConnectivityResult>> _connectivityChanges;
  final Future<ApiAvailabilityState> Function()? _checkApiAvailability;
  final int _serverFailureThreshold;
  int _consecutiveServerFailures = 0;

  static const String _dnsProbeHost = 'one.one.one.one';

  Stream<List<ConnectivityResult>> get connectivityChanges =>
      _connectivityChanges;

  Future<DeviceLocationStatus> checkLocationStatus() async {
    final serviceEnabled = await _isLocationServiceEnabled();
    if (!serviceEnabled) return DeviceLocationStatus.serviceDisabled;

    final permission = await _checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return DeviceLocationStatus.permissionDeniedForever;
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      return DeviceLocationStatus.permissionDenied;
    }
    return DeviceLocationStatus.ready;
  }

  Future<DeviceInternetStatus> checkInternetStatus() async {
    final connectivityResults = await _checkConnectivity();
    final hasTransport = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );
    if (!hasTransport) return DeviceInternetStatus.probableAirplaneMode;

    try {
      final lookupResult = await _dnsLookup(_dnsProbeHost);
      final hasInternet = lookupResult.isNotEmpty;
      return hasInternet
          ? DeviceInternetStatus.online
          : DeviceInternetStatus.noInternet;
    } on SocketException {
      return DeviceInternetStatus.noInternet;
    } catch (_) {
      return DeviceInternetStatus.noInternet;
    }
  }

  Future<DeviceStatusSnapshot> detectIssue() async {
    final locationStatus = await checkLocationStatus();
    if (locationStatus == DeviceLocationStatus.serviceDisabled) {
      _consecutiveServerFailures = 0;
      return _snapshotFor(
        DeviceIssue.locationServiceOff,
        'Localisation',
        'La localisation est desactivee. Activez-la pour continuer.',
      );
    }
    if (locationStatus == DeviceLocationStatus.permissionDeniedForever) {
      _consecutiveServerFailures = 0;
      return _snapshotFor(
        DeviceIssue.locationPermissionDeniedForever,
        'Localisation',
        'Permission localisation refusee definitivement.',
      );
    }
    if (locationStatus == DeviceLocationStatus.permissionDenied) {
      _consecutiveServerFailures = 0;
      return _snapshotFor(
        DeviceIssue.locationPermissionDenied,
        'Localisation',
        'Permission localisation non accordee.',
      );
    }

    final internetStatus = await checkInternetStatus();
    if (internetStatus == DeviceInternetStatus.probableAirplaneMode) {
      _consecutiveServerFailures = 0;
      return _snapshotFor(
        DeviceIssue.probableAirplaneMode,
        'Mode avion probable',
        'Aucune connexion detectee (mode avion probable).',
      );
    }
    if (internetStatus == DeviceInternetStatus.noInternet) {
      _consecutiveServerFailures = 0;
      return _snapshotFor(
        DeviceIssue.noInternet,
        'Connexion internet',
        'Pas de connexion internet.',
      );
    }

    final apiStatus = await checkApiStatus();
    if (apiStatus == ApiAvailabilityState.unreachable) {
      return _snapshotFor(
        DeviceIssue.serverUnreachable,
        'Serveur indisponible',
        'Connexion au serveur interrompue. Reconnexion en cours.',
      );
    }

    return _snapshotFor(DeviceIssue.none, '', '');
  }

  Future<ApiAvailabilityState> checkApiStatus() async {
    final check = _checkApiAvailability;
    if (check == null) return ApiAvailabilityState.reachable;

    final guardState = ApiAvailabilityGuard.instance.state;
    final status = await check();
    if (status == ApiAvailabilityState.unreachable) {
      if (guardState == ApiAvailabilityState.unreachable) {
        return ApiAvailabilityState.unreachable;
      }
      _consecutiveServerFailures++;
      return _consecutiveServerFailures >= _serverFailureThreshold
          ? ApiAvailabilityState.unreachable
          : ApiAvailabilityState.checking;
    }

    _consecutiveServerFailures = 0;
    return status;
  }

  DeviceStatusSnapshot _snapshotFor(
    DeviceIssue issue,
    String title,
    String message,
  ) {
    return DeviceStatusSnapshot(
      issue: issue,
      title: title,
      message: message,
      checkedAt: DateTime.now(),
    );
  }
}
