library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/api_availability_guard.dart';
import '../models/device_status_snapshot.dart';
import '../models/top_alert_item.dart';
import 'device_status_alert_visibility_provider.dart';
import 'device_status_provider.dart';
import 'top_alerts_provider.dart';

final deviceStatusAlertCoordinatorProvider = Provider<void>((ref) {
  final alertsAreVisible = ref.watch(deviceStatusAlertVisibilityProvider);

  if (!alertsAreVisible) {
    Future.microtask(() {
      if (!ref.mounted) return;
      ref
          .read(topAlertsProvider.notifier)
          .dismissBySource(TopAlertSource.deviceStatus);
    });
  }

  void syncAlert(AsyncValue<DeviceStatusSnapshot> value) {
    final snapshot = value.asData?.value;
    if (snapshot == null) return;
    _syncApiGuard(snapshot.issue);
    if (!alertsAreVisible) {
      ref
          .read(topAlertsProvider.notifier)
          .dismissBySource(TopAlertSource.deviceStatus);
      return;
    }
    ref.read(topAlertsProvider.notifier).pushOrUpdateDeviceAlert(snapshot);
  }

  Future.microtask(() {
    if (!ref.mounted) return;
    syncAlert(ref.read(deviceStatusProvider));
  });

  ref.listen<AsyncValue<DeviceStatusSnapshot>>(
    deviceStatusProvider,
    (_, next) => syncAlert(next),
  );
});

void _syncApiGuard(DeviceIssue issue) {
  final guard = ApiAvailabilityGuard.instance;
  switch (issue) {
    case DeviceIssue.noInternet:
    case DeviceIssue.probableAirplaneMode:
    case DeviceIssue.serverUnreachable:
      guard.setState(ApiAvailabilityState.unreachable);
      return;
    case DeviceIssue.none:
      guard.setState(ApiAvailabilityState.reachable);
      return;
    case DeviceIssue.locationServiceOff:
    case DeviceIssue.locationPermissionDenied:
    case DeviceIssue.locationPermissionDeniedForever:
      return;
  }
}
