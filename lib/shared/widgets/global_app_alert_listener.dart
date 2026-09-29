library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/app_alert_service.dart';
import '../providers/app_alert_provider.dart';
import '../providers/device_status_alert_coordinator_provider.dart';
import '../models/top_alert_item.dart';
import 'app_snack_bar.dart';
import 'top_alert_stack.dart';

class GlobalAppAlertListener extends ConsumerStatefulWidget {
  const GlobalAppAlertListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<GlobalAppAlertListener> createState() =>
      _GlobalAppAlertListenerState();
}

class _GlobalAppAlertListenerState
    extends ConsumerState<GlobalAppAlertListener> {
  StreamSubscription<AppAlertMessage>? _subscription;
  AppAlertMessage? _lastSnackAlert;
  DateTime? _lastSnackAt;

  @override
  void initState() {
    super.initState();
    _subscription = ref
        .read(appAlertServiceProvider)
        .alerts
        .listen(_handleAlertMessage);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(deviceStatusAlertCoordinatorProvider);
    return Stack(
      children: [
        widget.child,
        const TopAlertsStack(source: TopAlertSource.deviceStatus),
      ],
    );
  }

  void _handleAlertMessage(AppAlertMessage alert) {
    if (!mounted) return;
    if (_isDuplicateSnack(alert)) return;
    _lastSnackAlert = alert;
    _lastSnackAt = DateTime.now();

    switch (alert.type) {
      case AppAlertType.info:
        AppSnackBar.showInfo(
          context,
          alert.message,
          duration: alert.duration,
          atTop: alert.atTop,
        );
        return;
      case AppAlertType.success:
        AppSnackBar.showSuccess(
          context,
          alert.message,
          duration: alert.duration,
          atTop: alert.atTop,
        );
        return;
      case AppAlertType.error:
        AppSnackBar.showError(
          context,
          alert.message,
          duration: alert.duration,
          atTop: alert.atTop,
        );
        return;
    }
  }

  bool _isDuplicateSnack(AppAlertMessage alert) {
    final previous = _lastSnackAlert;
    final shownAt = _lastSnackAt;
    if (previous == null || shownAt == null) return false;
    final sameAlert =
        previous.type == alert.type && previous.message == alert.message;
    return sameAlert && DateTime.now().difference(shownAt).inSeconds < 2;
  }
}
