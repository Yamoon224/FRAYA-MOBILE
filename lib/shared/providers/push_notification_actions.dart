library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/realtime_events.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/utils/logger.dart';
import '../../features/driver/auth/providers/driver_auth_provider.dart';
import '../../features/driver/history/providers/driver_history_provider.dart';
import '../../features/driver/home/providers/driver_home_provider.dart';
import '../../features/passenger/booking/providers/active_ride_provider.dart';
import '../../features/passenger/booking/providers/booking_flow_provider.dart';
import 'app_alert_provider.dart';
import 'app_providers.dart';
import 'realtime_providers.dart';

final passengerPushNotificationActionsProvider =
    Provider<PassengerPushNotificationActions>((ref) {
      return _DefaultPassengerPushNotificationActions(ref);
    });

final driverPushNotificationActionsProvider =
    Provider<DriverPushNotificationActions>((ref) {
      return _DefaultDriverPushNotificationActions(ref);
    });

abstract class PassengerPushNotificationActions {
  Future<void> refreshRide(String? rideId);
  bool get hasActiveRide;
  void clearActiveRide();
  void showInfo(String message);
  void goNamed(String routeName);
}

abstract class DriverPushNotificationActions {
  bool get isOnline;
  Future<void> refreshHome();
  void emitRideStatus(PushNotificationPayload payload, String status);
  void invalidateHistory();
  void refreshProfile();
  void showInfo(String message);
  void goNamed(String routeName);
}

class _DefaultPassengerPushNotificationActions
    implements PassengerPushNotificationActions {
  const _DefaultPassengerPushNotificationActions(this._ref);

  final Ref _ref;

  @override
  Future<void> refreshRide(String? rideId) {
    return _ref
        .read(bookingFlowProvider.notifier)
        .handleRideAcceptedRealtime(rideId);
  }

  @override
  bool get hasActiveRide => _ref.read(activeRideControllerProvider) != null;

  @override
  void clearActiveRide() {
    _ref.read(activeRideControllerProvider.notifier).clear();
  }

  @override
  void showInfo(String message) {
    _ref.read(appAlertServiceProvider).showInfo(message);
  }

  @override
  void goNamed(String routeName) => _goNamed(_ref, routeName);
}

class _DefaultDriverPushNotificationActions
    implements DriverPushNotificationActions {
  const _DefaultDriverPushNotificationActions(this._ref);

  final Ref _ref;

  @override
  bool get isOnline => _ref.read(driverHomeProvider).isOnline;

  @override
  Future<void> refreshHome() {
    return _ref.read(driverHomeProvider.notifier).refreshHome();
  }

  @override
  void emitRideStatus(PushNotificationPayload payload, String status) {
    final rideId = payload.rideId;
    if (rideId == null || rideId.isEmpty) return;
    _ref
        .read(driverRideStatusRealtimeProvider.notifier)
        .state = DriverRideStatusRealtimeEvent(
      rideId: rideId,
      status: status,
      updatedAt: DateTime.now(),
      reason: payload.body,
      changedBy: payload.cancelledBy,
    );
  }

  @override
  void invalidateHistory() {
    _ref.invalidate(driverHistoryRidesProvider);
  }

  @override
  void refreshProfile() {
    unawaited(_ref.read(driverAuthProvider.notifier).refreshProfile());
  }

  @override
  void showInfo(String message) {
    _ref.read(appAlertServiceProvider).showInfo(message);
  }

  @override
  void goNamed(String routeName) => _goNamed(_ref, routeName);
}

void _goNamed(Ref ref, String routeName) {
  try {
    ref.read(appRouterProvider).goNamed(routeName);
  } catch (error, stackTrace) {
    logger.warning('Navigation push ignoree: $routeName', error, stackTrace);
  }
}
