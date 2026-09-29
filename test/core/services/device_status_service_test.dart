import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/api_availability_guard.dart';
import 'package:fraya_mobile/core/services/device_status_service.dart';
import 'package:fraya_mobile/shared/models/device_status_snapshot.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  setUp(ApiAvailabilityGuard.instance.reset);
  tearDown(ApiAvailabilityGuard.instance.reset);

  DeviceStatusService buildService({
    required bool isLocationEnabled,
    required LocationPermission permission,
    required List<ConnectivityResult> connectivityResults,
    Future<List<InternetAddress>> Function(String host)? dnsLookup,
    Future<ApiAvailabilityState> Function()? checkApiAvailability,
  }) {
    return DeviceStatusService(
      isLocationServiceEnabled: () async => isLocationEnabled,
      checkPermission: () async => permission,
      checkConnectivity: () async => connectivityResults,
      dnsLookup: dnsLookup ?? ((_) async => [InternetAddress.loopbackIPv4]),
      connectivityChanges: const Stream<List<ConnectivityResult>>.empty(),
      checkApiAvailability: checkApiAvailability,
    );
  }

  test(
    'detectIssue returns locationServiceOff when location is disabled',
    () async {
      final service = buildService(
        isLocationEnabled: false,
        permission: LocationPermission.always,
        connectivityResults: const [ConnectivityResult.wifi],
      );

      final snapshot = await service.detectIssue();
      expect(snapshot.issue, DeviceIssue.locationServiceOff);
      expect(snapshot.title, 'Localisation');
    },
  );

  test(
    'detectIssue returns locationPermissionDenied when permission is denied',
    () async {
      final service = buildService(
        isLocationEnabled: true,
        permission: LocationPermission.denied,
        connectivityResults: const [ConnectivityResult.wifi],
      );

      final snapshot = await service.detectIssue();
      expect(snapshot.issue, DeviceIssue.locationPermissionDenied);
      expect(snapshot.title, 'Localisation');
    },
  );

  test(
    'detectIssue returns locationPermissionDeniedForever when permission is denied forever',
    () async {
      final service = buildService(
        isLocationEnabled: true,
        permission: LocationPermission.deniedForever,
        connectivityResults: const [ConnectivityResult.wifi],
      );

      final snapshot = await service.detectIssue();
      expect(snapshot.issue, DeviceIssue.locationPermissionDeniedForever);
      expect(snapshot.title, 'Localisation');
    },
  );

  test(
    'checkInternetStatus returns probableAirplaneMode when connectivity is none',
    () async {
      final service = buildService(
        isLocationEnabled: true,
        permission: LocationPermission.always,
        connectivityResults: const [ConnectivityResult.none],
      );

      final internetStatus = await service.checkInternetStatus();
      expect(internetStatus, DeviceInternetStatus.probableAirplaneMode);
    },
  );

  test(
    'checkInternetStatus returns noInternet when DNS lookup fails',
    () async {
      final service = buildService(
        isLocationEnabled: true,
        permission: LocationPermission.always,
        connectivityResults: const [ConnectivityResult.wifi],
        dnsLookup: (_) async => throw const SocketException('offline'),
      );

      final internetStatus = await service.checkInternetStatus();
      expect(internetStatus, DeviceInternetStatus.noInternet);
    },
  );

  test(
    'detectIssue returns none when location and internet are available',
    () async {
      final service = buildService(
        isLocationEnabled: true,
        permission: LocationPermission.always,
        connectivityResults: const [ConnectivityResult.wifi],
      );

      final snapshot = await service.detectIssue();
      expect(snapshot.issue, DeviceIssue.none);
      expect(snapshot.title, isEmpty);
    },
  );

  test(
    'detectIssue returns internet title when internet is unavailable',
    () async {
      final service = buildService(
        isLocationEnabled: true,
        permission: LocationPermission.always,
        connectivityResults: const [ConnectivityResult.wifi],
        dnsLookup: (_) async => throw const SocketException('offline'),
      );

      final snapshot = await service.detectIssue();
      expect(snapshot.issue, DeviceIssue.noInternet);
      expect(snapshot.title, 'Connexion internet');
    },
  );

  test(
    'detectIssue confirms serverUnreachable after repeated failures',
    () async {
      final service = buildService(
        isLocationEnabled: true,
        permission: LocationPermission.always,
        connectivityResults: const [ConnectivityResult.wifi],
        checkApiAvailability: () async => ApiAvailabilityState.unreachable,
      );

      final first = await service.detectIssue();
      final second = await service.detectIssue();

      expect(first.issue, DeviceIssue.none);
      expect(second.issue, DeviceIssue.serverUnreachable);
    },
  );

  test('detectIssue clears server failures after backend recovery', () async {
    var reachable = false;
    final service = buildService(
      isLocationEnabled: true,
      permission: LocationPermission.always,
      connectivityResults: const [ConnectivityResult.wifi],
      checkApiAvailability: () async => reachable
          ? ApiAvailabilityState.reachable
          : ApiAvailabilityState.unreachable,
    );

    await service.detectIssue();
    reachable = true;
    final recovered = await service.detectIssue();

    expect(recovered.issue, DeviceIssue.none);
  });
}
