import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/api_availability_guard.dart';
import 'package:fraya_mobile/core/services/device_status_service.dart';
import 'package:fraya_mobile/shared/models/device_status_snapshot.dart';
import 'package:fraya_mobile/shared/providers/device_status_provider.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(ApiAvailabilityGuard.instance.reset);
  tearDown(ApiAvailabilityGuard.instance.reset);

  test('deviceStatusProvider deduplicates repeated issues', () async {
    final fakeService = _FakeDeviceStatusService(
      initialIssue: DeviceIssue.noInternet,
    );
    final container = ProviderContainer(
      overrides: [deviceStatusServiceProvider.overrideWithValue(fakeService)],
    );
    addTearDown(() async {
      container.dispose();
      await fakeService.dispose();
    });

    final sub = container.listen(deviceStatusProvider, (_, _) {});
    addTearDown(sub.close);
    final first = await container.read(deviceStatusProvider.future);

    expect(first.issue, DeviceIssue.noInternet);
    fakeService.emitConnectivityChange();
    await Future<void>.delayed(const Duration(milliseconds: 1700));

    expect(
      container.read(deviceStatusProvider).asData?.value.issue,
      DeviceIssue.noInternet,
    );
  });

  test(
    'deviceStatusProvider refreshes when location tracking is activated',
    () async {
      final fakeService = _FakeDeviceStatusService(
        initialIssue: DeviceIssue.none,
      );
      final container = ProviderContainer(
        overrides: [deviceStatusServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(() async {
        container.dispose();
        await fakeService.dispose();
      });

      final sub = container.listen(deviceStatusProvider, (_, _) {});
      addTearDown(sub.close);
      final first = await container.read(deviceStatusProvider.future);

      expect(first.issue, DeviceIssue.none);
      fakeService.issue = DeviceIssue.locationServiceOff;
      container.read(locationTrackingRequestCountProvider.notifier).state++;
      await _waitFor(
        () =>
            container.read(deviceStatusProvider).asData?.value.issue ==
            DeviceIssue.locationServiceOff,
      );

      expect(
        container.read(deviceStatusProvider).asData?.value.issue,
        DeviceIssue.locationServiceOff,
      );
    },
  );

  test('deviceStatusProvider emits none when an issue is resolved', () async {
    final fakeService = _FakeDeviceStatusService(
      initialIssue: DeviceIssue.noInternet,
    );
    final container = ProviderContainer(
      overrides: [deviceStatusServiceProvider.overrideWithValue(fakeService)],
    );
    addTearDown(() async {
      container.dispose();
      await fakeService.dispose();
    });

    final sub = container.listen(deviceStatusProvider, (_, _) {});
    addTearDown(sub.close);
    final first = await container.read(deviceStatusProvider.future);

    expect(first.issue, DeviceIssue.noInternet);
    fakeService.issue = DeviceIssue.none;
    fakeService.emitConnectivityChange();
    await _waitFor(
      () =>
          container.read(deviceStatusProvider).asData?.value.issue ==
          DeviceIssue.none,
    );

    expect(
      container.read(deviceStatusProvider).asData?.value.issue,
      DeviceIssue.none,
    );
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 80; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

class _FakeDeviceStatusService extends DeviceStatusService {
  _FakeDeviceStatusService({required this.initialIssue})
    : _connectivityController =
          StreamController<List<ConnectivityResult>>.broadcast(),
      super(
        isLocationServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.always,
        checkConnectivity: () async => const [ConnectivityResult.wifi],
        dnsLookup: (_) async => [InternetAddress.loopbackIPv4],
      ) {
    issue = initialIssue;
  }

  final StreamController<List<ConnectivityResult>> _connectivityController;
  final DeviceIssue initialIssue;
  late DeviceIssue issue;

  @override
  Stream<List<ConnectivityResult>> get connectivityChanges =>
      _connectivityController.stream;

  @override
  Future<DeviceStatusSnapshot> detectIssue() async {
    return DeviceStatusSnapshot(
      issue: issue,
      title: 'fake title',
      message: 'fake',
      checkedAt: DateTime(2026, 1, 1),
    );
  }

  void emitConnectivityChange() {
    _connectivityController.add(const [ConnectivityResult.wifi]);
  }

  Future<void> dispose() async {
    await _connectivityController.close();
  }
}
