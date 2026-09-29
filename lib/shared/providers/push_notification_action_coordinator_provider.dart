library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/router/route_names.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/utils/logger.dart';
import '../../features/driver/auth/providers/driver_auth_provider.dart';
import '../../features/passenger/auth/providers/passenger_auth_provider.dart';
import '../../shared/models/auth_state.dart';
import 'push_notification_actions.dart';
import 'push_notification_provider.dart';

final pushNotificationActionCoordinatorProvider = Provider<void>((ref) {
  final controller = _PushNotificationActionCoordinator(ref);
  ref.onDispose(controller.dispose);
  controller.initialize();
});

final pushNotificationAuthGateProvider = Provider<PushNotificationAuthGate>((
  ref,
) {
  return _DefaultPushNotificationAuthGate(ref);
});

abstract class PushNotificationAuthGate {
  bool get isPassengerAuthenticated;
  bool get isDriverAuthenticated;
}

class _DefaultPushNotificationAuthGate implements PushNotificationAuthGate {
  const _DefaultPushNotificationAuthGate(this._ref);

  final Ref _ref;

  @override
  bool get isPassengerAuthenticated =>
      _ref.read(passengerAuthProvider).status == AuthStatus.authenticated;

  @override
  bool get isDriverAuthenticated =>
      _ref.read(driverAuthProvider).status == AuthStatus.authenticated;
}

class _PushNotificationActionCoordinator {
  _PushNotificationActionCoordinator(this._ref);

  final Ref _ref;
  final List<String> _seenNotificationIds = <String>[];
  StreamSubscription<PushNotificationPayload>? _tapSub;
  StreamSubscription<PushNotificationPayload>? _receivedSub;
  bool _disposed = false;

  void initialize() {
    _tapSub = _ref
        .watch(pushNotificationTapStreamProvider)
        .listen(
          (payload) => unawaited(_handle(payload, opened: true)),
          onError: _logError,
        );
    _receivedSub = _ref
        .watch(pushNotificationReceivedStreamProvider)
        .listen(
          (payload) => unawaited(_handle(payload, opened: false)),
          onError: _logError,
        );
  }

  Future<void> _handle(
    PushNotificationPayload payload, {
    required bool opened,
  }) async {
    if (_disposed || !payload.isSupported || !_matchesActiveFlavor(payload)) {
      return;
    }
    if (_isDuplicate(payload)) return;

    if (AppConfig.instance.isPassenger) {
      await _handlePassenger(payload, opened: opened);
      return;
    }
    if (AppConfig.instance.isDriver) {
      await _handleDriver(payload, opened: opened);
    }
  }

  Future<void> _handlePassenger(
    PushNotificationPayload payload, {
    required bool opened,
  }) async {
    if (!_ref.read(pushNotificationAuthGateProvider).isPassengerAuthenticated) {
      return;
    }
    final actions = _ref.read(passengerPushNotificationActionsProvider);
    switch (payload.type) {
      case 'ride_accepted':
      case 'driver_arrived':
      case 'ride_started':
        await actions.refreshRide(payload.rideId);
        if (opened && actions.hasActiveRide) {
          actions.goNamed(RouteNames.rideTracking);
        }
      case 'ride_completed':
        await actions.refreshRide(payload.rideId);
        if (opened) actions.goNamed(RouteNames.rideComplete);
      case 'ride_cancelled':
        await actions.refreshRide(payload.rideId);
        actions.clearActiveRide();
        if (opened) actions.goNamed(RouteNames.passengerHome);
      case 'drivers_nearby':
        break;
      default:
        break;
    }
  }

  Future<void> _handleDriver(
    PushNotificationPayload payload, {
    required bool opened,
  }) async {
    if (!_ref.read(pushNotificationAuthGateProvider).isDriverAuthenticated) {
      return;
    }
    final actions = _ref.read(driverPushNotificationActionsProvider);
    switch (payload.type) {
      case 'new_ride_available':
        if (actions.isOnline) {
          await actions.refreshHome();
        }
        if (opened) actions.goNamed(RouteNames.driverHome);
      case 'ride_accepted':
        await actions.refreshHome();
        if (opened) actions.goNamed(RouteNames.driverHome);
      case 'ride_cancelled':
        actions.emitRideStatus(payload, 'CANCELLED');
        await actions.refreshHome();
        if (opened) actions.goNamed(RouteNames.driverHome);
      case 'ride_completed':
        actions.emitRideStatus(payload, 'COMPLETED');
        await actions.refreshHome();
        actions.invalidateHistory();
        if (opened) actions.goNamed(RouteNames.driverHome);
      case 'driver_rated':
        actions.invalidateHistory();
        actions.refreshProfile();
      default:
        break;
    }
  }

  bool _matchesActiveFlavor(PushNotificationPayload payload) {
    final role = payload.recipientRole;
    if (role == null || role.isEmpty) return true;
    if (AppConfig.instance.isPassenger) return role == 'PASSENGER';
    if (AppConfig.instance.isDriver) return role == 'DRIVER';
    return false;
  }

  bool _isDuplicate(PushNotificationPayload payload) {
    final id = payload.notificationId;
    if (id == null || id.isEmpty) return false;
    if (_seenNotificationIds.contains(id)) return true;
    _seenNotificationIds.add(id);
    if (_seenNotificationIds.length > 32) {
      _seenNotificationIds.removeAt(0);
    }
    return false;
  }

  void _logError(Object error, StackTrace stackTrace) {
    logger.warning('Push notification action error', error, stackTrace);
  }

  void dispose() {
    _disposed = true;
    _tapSub?.cancel();
    _receivedSub?.cancel();
  }
}
