library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device_status_snapshot.dart';
import '../models/top_alert_item.dart';

final topAlertsProvider =
    NotifierProvider<TopAlertsController, List<TopAlertItem>>(
      TopAlertsController.new,
      isAutoDispose: true,
    );

class TopAlertsController extends Notifier<List<TopAlertItem>> {
  static const int _maxVisibleAlerts = 3;

  @override
  List<TopAlertItem> build() => const <TopAlertItem>[];

  void pushOrUpdateDeviceAlert(DeviceStatusSnapshot snapshot) {
    if (!snapshot.hasIssue) {
      dismissBySource(TopAlertSource.deviceStatus);
      return;
    }

    final id = 'device_status_${snapshot.issue.name}';
    final item = TopAlertItem(
      id: id,
      severity: TopAlertSeverity.error,
      title: snapshot.title,
      message: snapshot.message,
      source: TopAlertSource.deviceStatus,
      createdAt: snapshot.checkedAt,
    );

    final next = state
        .where((alert) => alert.source != TopAlertSource.deviceStatus)
        .toList(growable: true);
    next.insert(0, item);
    if (next.length > _maxVisibleAlerts) {
      next.removeRange(_maxVisibleAlerts, next.length);
    }
    state = next;
  }

  void dismiss(String id) {
    state = state.where((alert) => alert.id != id).toList(growable: false);
  }

  void dismissBySource(TopAlertSource source) {
    state = state
        .where((alert) => alert.source != source)
        .toList(growable: false);
  }
}
