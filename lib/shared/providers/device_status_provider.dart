library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/api_availability_guard.dart';
import '../../core/services/api_availability_service.dart';
import '../../core/services/device_status_service.dart';
import '../models/device_status_snapshot.dart';
import 'location_provider.dart';

final apiAvailabilityServiceProvider = Provider<ApiAvailabilityService>((ref) {
  return ApiAvailabilityService();
});

final deviceStatusServiceProvider = Provider<DeviceStatusService>((ref) {
  final apiAvailabilityService = ref.watch(apiAvailabilityServiceProvider);
  return DeviceStatusService(
    checkApiAvailability: apiAvailabilityService.check,
  );
});

final deviceStatusProvider = StreamProvider.autoDispose<DeviceStatusSnapshot>((
  ref,
) {
  final service = ref.watch(deviceStatusServiceProvider);
  final controller = StreamController<DeviceStatusSnapshot>();
  DeviceIssue? lastIssue;
  var isAppActive = true;
  Timer? debounceTimer;
  Timer? pollingTimer;
  Timer? resumeDelayTimer;

  Future<void> emitCurrentStatus() async {
    if (!isAppActive) return;
    final snapshot = await service.detectIssue();
    if (!ref.mounted) return;
    if (snapshot.issue == lastIssue) return;
    lastIssue = snapshot.issue;
    controller.add(snapshot);
  }

  final lifecycleObserver = _AppLifecycleObserver((state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debounceTimer?.cancel();
      resumeDelayTimer?.cancel();
      isAppActive = false;
    } else if (state == AppLifecycleState.resumed) {
      resumeDelayTimer?.cancel();
      resumeDelayTimer = Timer(const Duration(seconds: 2), () {
        isAppActive = true;
        unawaited(emitCurrentStatus());
      });
    }
  });
  WidgetsBinding.instance.addObserver(lifecycleObserver);

  final connectivitySub = service.connectivityChanges.listen((_) {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      unawaited(emitCurrentStatus());
    });
  });
  final availabilitySub = ApiAvailabilityGuard.instance.changes.listen((_) {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(emitCurrentStatus());
    });
  });

  pollingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
    unawaited(emitCurrentStatus());
  });

  ref.listen<int>(locationTrackingRequestCountProvider, (previous, next) {
    final wasDisabled = (previous ?? 0) <= 0;
    if (wasDisabled && next > 0) {
      unawaited(emitCurrentStatus());
    }
  });

  Timer.run(() => unawaited(emitCurrentStatus()));

  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(lifecycleObserver);
    connectivitySub.cancel();
    availabilitySub.cancel();
    debounceTimer?.cancel();
    pollingTimer?.cancel();
    resumeDelayTimer?.cancel();
    controller.close();
  });

  return controller.stream;
});

class _AppLifecycleObserver extends WidgetsBindingObserver {
  _AppLifecycleObserver(this._onStateChange);

  final void Function(AppLifecycleState) _onStateChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _onStateChange(state);
  }
}
