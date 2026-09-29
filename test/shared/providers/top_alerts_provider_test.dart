import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/shared/models/device_status_snapshot.dart';
import 'package:fraya_mobile/shared/models/top_alert_item.dart';
import 'package:fraya_mobile/shared/providers/top_alerts_provider.dart';

void main() {
  DeviceStatusSnapshot snapshotFor(
    DeviceIssue issue, {
    String? title,
    String? message,
    DateTime? checkedAt,
  }) {
    return DeviceStatusSnapshot(
      issue: issue,
      title: title ?? issue.name,
      message: message ?? issue.name,
      checkedAt: checkedAt ?? DateTime(2026, 5, 29),
    );
  }

  test('pushOrUpdateDeviceAlert adds one persistent alert entry', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(topAlertsProvider.notifier)
        .pushOrUpdateDeviceAlert(snapshotFor(DeviceIssue.noInternet));

    final alerts = container.read(topAlertsProvider);
    expect(alerts, hasLength(1));
    expect(alerts.first.id, 'device_status_noInternet');
    expect(alerts.first.source, TopAlertSource.deviceStatus);
  });

  test(
    'pushOrUpdateDeviceAlert deduplicates same issue and updates message',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(topAlertsProvider.notifier);
      notifier.pushOrUpdateDeviceAlert(
        snapshotFor(DeviceIssue.noInternet, message: 'old'),
      );
      notifier.pushOrUpdateDeviceAlert(
        snapshotFor(DeviceIssue.noInternet, message: 'new'),
      );

      final alerts = container.read(topAlertsProvider);
      expect(alerts, hasLength(1));
      expect(alerts.first.message, 'new');
    },
  );

  test('pushOrUpdateDeviceAlert keeps one device alert', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(topAlertsProvider.notifier);
    notifier.pushOrUpdateDeviceAlert(snapshotFor(DeviceIssue.noInternet));
    notifier.pushOrUpdateDeviceAlert(
      snapshotFor(DeviceIssue.locationServiceOff),
    );
    notifier.pushOrUpdateDeviceAlert(
      snapshotFor(DeviceIssue.locationPermissionDenied),
    );
    notifier.pushOrUpdateDeviceAlert(
      snapshotFor(DeviceIssue.locationPermissionDeniedForever),
    );

    final alerts = container.read(topAlertsProvider);
    expect(alerts, hasLength(1));
    expect(alerts.first.id, 'device_status_locationPermissionDeniedForever');
  });

  test('dismiss removes alert by id', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(topAlertsProvider.notifier);
    notifier.pushOrUpdateDeviceAlert(snapshotFor(DeviceIssue.noInternet));
    final firstId = container.read(topAlertsProvider).first.id;
    notifier.dismiss(firstId);

    expect(container.read(topAlertsProvider), isEmpty);
  });

  test('dismissBySource clears device alerts', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(topAlertsProvider.notifier);
    notifier.pushOrUpdateDeviceAlert(snapshotFor(DeviceIssue.noInternet));
    notifier.dismissBySource(TopAlertSource.deviceStatus);

    expect(container.read(topAlertsProvider), isEmpty);
  });

  test('issue none auto-clears device alerts', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(topAlertsProvider.notifier);
    notifier.pushOrUpdateDeviceAlert(snapshotFor(DeviceIssue.noInternet));
    notifier.pushOrUpdateDeviceAlert(snapshotFor(DeviceIssue.none));

    expect(container.read(topAlertsProvider), isEmpty);
  });
}
