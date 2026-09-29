library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../features/driver/home/providers/driver_home_provider.dart';
import '../../features/passenger/booking/providers/active_ride_check_provider.dart';
import '../../features/passenger/booking/providers/booking_flow_provider.dart';
import '../../features/passenger/booking/providers/booking_route_refresh_provider.dart';
import '../../features/passenger/booking/providers/ride_categories_provider.dart';
import '../../features/passenger/booking/providers/route_directions_provider.dart';
import '../../features/passenger/map/providers/nearby_drivers_provider.dart';
import 'device_status_provider.dart';
import 'location_provider.dart';
import 'realtime_session_provider.dart';

final appResumeRefreshThresholdProvider = Provider<Duration>(
  (_) => kDebugMode ? const Duration(seconds: 10) : const Duration(minutes: 3),
);

final appResumeRefreshActionsProvider = Provider<AppResumeRefreshActions>((
  ref,
) {
  return DefaultAppResumeRefreshActions(ref);
});

abstract interface class AppResumeRefreshActions {
  Future<void> refreshAfterLongBackground();
}

class DefaultAppResumeRefreshActions implements AppResumeRefreshActions {
  const DefaultAppResumeRefreshActions(this._ref);

  final Ref _ref;

  @override
  Future<void> refreshAfterLongBackground() async {
    _resumeRefreshLog('Starting app resume refresh actions.');
    final deviceStatusRefresh = _refreshDeviceStatus();
    _ref.read(realtimeSessionReconnectSignalProvider.notifier).state++;
    _resumeRefreshLog('Realtime reconnect signal sent.');

    if (AppConfig.instance.isPassenger) {
      _resumeRefreshLog('Passenger flavor detected.');
      await Future.wait<void>([deviceStatusRefresh, _refreshPassenger()]);
      _resumeRefreshLog('Passenger app resume refresh actions completed.');
      return;
    }
    if (AppConfig.instance.isDriver) {
      _resumeRefreshLog('Driver flavor detected.');
      await Future.wait<void>([deviceStatusRefresh, _refreshDriver()]);
      _resumeRefreshLog('Driver app resume refresh actions completed.');
      return;
    }

    await deviceStatusRefresh;
    _resumeRefreshLog('Generic app resume refresh actions completed.');
  }

  Future<void> _refreshDeviceStatus() async {
    _resumeRefreshLog('Refreshing device status.');
    _ref.invalidate(deviceStatusProvider);
    try {
      await _ref
          .read(deviceStatusProvider.future)
          .timeout(const Duration(seconds: 6));
      _resumeRefreshLog('Device status refresh completed.');
    } catch (_) {
      _resumeRefreshLog('Device status refresh timed out or failed silently.');
      // Keep resume refresh silent. The regular device status stream will
      // surface any persistent issue once it can resolve a fresh snapshot.
    }
  }

  Future<void> _refreshPassenger() async {
    _resumeRefreshLog('Refreshing passenger location snapshot and address.');
    _ref.read(passengerLocationSnapshotRefreshTriggerProvider.notifier).state++;
    _ref.invalidate(passengerUserAddressProvider);

    _resumeRefreshLog('Refreshing nearby drivers.');
    await _ref
        .read(nearbyDriversProvider.notifier)
        .refreshNow(clearStale: true);

    _resumeRefreshLog('Refreshing passenger active ride status.');
    _ref.invalidate(activeRideCheckProvider);
    await _ref.read(bookingFlowProvider.notifier).hardRefreshStatus();

    if (_ref.read(bookingFlowProvider) != BookingFlowState.routePreview) {
      _resumeRefreshLog('Route pricing refresh skipped: not in routePreview.');
      return;
    }

    _resumeRefreshLog('Refreshing route preview directions and pricing.');
    _ref.read(bookingRouteRefreshControllerProvider).clearSnapshotAndRefresh();
    _ref.invalidate(routeDirectionsProvider);
    _ref.invalidate(rideCategoriesProvider);
  }

  Future<void> _refreshDriver() async {
    final state = _ref.read(driverHomeProvider);
    if (!state.isOnline) {
      _resumeRefreshLog('Driver home refresh skipped: driver is offline.');
      return;
    }
    _resumeRefreshLog('Refreshing driver home.');
    await _ref.read(driverHomeProvider.notifier).refreshHome();
  }
}

class AppResumeRefreshLifecycleCoordinator extends WidgetsBindingObserver {
  AppResumeRefreshLifecycleCoordinator({
    required Duration Function() threshold,
    required Future<void> Function() refreshAfterLongBackground,
    required void Function() dismissTransientAlerts,
    Future<void> Function()? handleAppDetached,
    Future<void> Function()? handleAppResumed,
    void Function(Object error, StackTrace stackTrace)? onError,
    DateTime Function()? now,
  }) : _threshold = threshold,
       _refreshAfterLongBackground = refreshAfterLongBackground,
       _dismissTransientAlerts = dismissTransientAlerts,
       _handleAppDetached = handleAppDetached,
       _handleAppResumed = handleAppResumed,
       _onError = onError,
       _now = now ?? DateTime.now;

  final Duration Function() _threshold;
  final Future<void> Function() _refreshAfterLongBackground;
  final void Function() _dismissTransientAlerts;
  final Future<void> Function()? _handleAppDetached;
  final Future<void> Function()? _handleAppResumed;
  final void Function(Object error, StackTrace stackTrace)? _onError;
  final DateTime Function() _now;

  DateTime? _backgroundedAt;
  bool _refreshInFlight = false;

  bool get isRefreshInFlight => _refreshInFlight;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumeRefreshLog('Lifecycle state received: ${state.name}.');
    if (state == AppLifecycleState.detached) {
      final handleAppDetached = _handleAppDetached;
      if (handleAppDetached != null) {
        unawaited(handleAppDetached());
      }
      return;
    }
    if (_isBackgroundState(state)) {
      if (_backgroundedAt == null) {
        _backgroundedAt = _now();
        _resumeRefreshLog('Background timestamp captured from ${state.name}.');
      }
      return;
    }

    if (state != AppLifecycleState.resumed) return;
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) {
      _resumeRefreshLog('Resume ignored: no background timestamp.');
      return;
    }
    _runLifecycleAction(_handleAppResumed, 'App resume action');
    if (_refreshInFlight) {
      _resumeRefreshLog('Resume ignored: refresh already in flight.');
      return;
    }

    final elapsed = _now().difference(backgroundedAt);
    final threshold = _threshold();
    _resumeRefreshLog(
      'Resume elapsed=${_formatDuration(elapsed)} threshold=${_formatDuration(threshold)}.',
    );
    if (elapsed < threshold) {
      _resumeRefreshLog('Resume refresh skipped: elapsed below threshold.');
      return;
    }

    _refreshInFlight = true;
    _resumeRefreshLog('Resume refresh started.');
    _dismissTransientAlerts();
    unawaited(
      _refreshAfterLongBackground()
          .catchError((Object error, StackTrace stackTrace) {
            _resumeRefreshLog('Resume refresh failed: $error');
            _onError?.call(error, stackTrace);
          })
          .whenComplete(() {
            _refreshInFlight = false;
            _resumeRefreshLog('Resume refresh finished.');
          }),
    );
  }

  bool _isBackgroundState(AppLifecycleState state) {
    return state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;
  }

  void _runLifecycleAction(
    Future<void> Function()? action,
    String description,
  ) {
    if (action == null) return;
    unawaited(
      action().catchError((Object error, StackTrace stackTrace) {
        _resumeRefreshLog('$description failed: $error');
        _onError?.call(error, stackTrace);
      }),
    );
  }
}

void _resumeRefreshLog(String message) {
  if (!kDebugMode) return;
  debugPrint('[ResumeRefresh] $message');
}

String _formatDuration(Duration duration) {
  final milliseconds = duration.inMilliseconds;
  if (milliseconds < 1000) return '${milliseconds}ms';
  final seconds = duration.inSeconds;
  if (seconds < 60) return '${seconds}s';
  final minutes = duration.inMinutes;
  final remainingSeconds = seconds % 60;
  if (remainingSeconds == 0) return '${minutes}m';
  return '${minutes}m ${remainingSeconds}s';
}
