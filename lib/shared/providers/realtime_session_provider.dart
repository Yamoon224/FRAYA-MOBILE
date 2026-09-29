library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/realtime/realtime_events.dart';
import '../../core/realtime/realtime_service.dart';
import '../../core/realtime/socket_health_state.dart';
import '../../core/services/auth_session_notifier.dart';
import '../../core/services/crash_reporting_service.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/logger.dart';
import '../../data/sources/local_storage.dart';
import '../../features/driver/auth/providers/driver_auth_provider.dart';
import '../../features/driver/home/providers/driver_home_provider.dart';
import '../../features/passenger/auth/providers/passenger_auth_provider.dart';
import '../../features/passenger/booking/providers/active_ride_provider.dart';
import '../../features/passenger/booking/providers/booking_flow_provider.dart';
import '../models/auth_state.dart';
import 'realtime_providers.dart';

final realtimeSessionReconnectSignalProvider = StateProvider<int>((_) => 0);

final realtimeSessionProvider = Provider<void>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  final controller = _RealtimeSessionController(ref, service);

  ref.onDispose(controller.dispose);
  controller.initialize();

  ref.listen<AuthState>(passengerAuthProvider, (_, next) {
    unawaited(controller.syncPassengerAuth(next));
  });

  ref.listen<AuthState>(driverAuthProvider, (_, next) {
    unawaited(controller.syncDriverAuth(next));
  });

  if (AppConfig.instance.isPassenger) {
    ref.listen(activeRideControllerProvider, (_, next) {
      controller.onActiveRideChanged(next?.rideId);
    });
  } else if (AppConfig.instance.isDriver) {
    ref.listen(driverHomeProvider, (_, next) {
      controller.onActiveRideChanged(next.activeRide?.rideId);
    });
  }

  ref.listen<int>(realtimeSessionReconnectSignalProvider, (_, _) {
    unawaited(controller.forceReconnect());
  });
});

class _RealtimeSessionController with WidgetsBindingObserver {
  _RealtimeSessionController(this._ref, this._service);

  final Ref _ref;
  final RealtimeService _service;

  StreamSubscription<SocketHealthState>? _healthSub;
  StreamSubscription<RidePositionUpdateEvent>? _positionSub;
  StreamSubscription<RideAcceptedEvent>? _rideAcceptedSub;
  StreamSubscription<DriverRideStatusRealtimeEvent>? _driverRideStatusSub;
  StreamSubscription<DriverRideStatusRealtimeEvent>? _passengerLifecycleSub;
  StreamSubscription<NewRideOfferEvent>? _newRideOfferSub;
  StreamSubscription<void>? _forceLogoutSub;
  StreamSubscription<void>? _tokenRefreshSub;
  int? _joinedRideId;
  bool _disposed = false;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    _healthSub = _service.healthStream.listen((health) {
      if (_disposed) return;
      _ref.read(realtimeHealthStateProvider.notifier).state = health;
      if (health == SocketHealthState.connected) {
        final rideId = AppConfig.instance.isPassenger
            ? _ref.read(activeRideControllerProvider)?.rideId
            : _ref.read(driverHomeProvider).activeRide?.rideId;
        onActiveRideChanged(rideId, force: true);
      }
    }, onError: _handleStreamError);

    _positionSub = _service.ridePositionUpdateStream.listen((event) {
      if (_disposed) return;
      final currentRide = _ref.read(activeRideControllerProvider);
      if (currentRide == null) return;
      if (event.rideId != null &&
          event.rideId!.isNotEmpty &&
          event.rideId != currentRide.rideId) {
        return;
      }
      _ref
          .read(activeRideControllerProvider.notifier)
          .updateLocation(LatLng(event.latitude, event.longitude));
    }, onError: _handleStreamError);

    _rideAcceptedSub = _service.rideAcceptedStream.listen((event) {
      if (_disposed) return;
      unawaited(
        _ref
            .read(bookingFlowProvider.notifier)
            .handleRideAcceptedRealtime(event.rideId),
      );
    }, onError: _handleStreamError);

    _driverRideStatusSub = _service.driverRideStatusStream.listen((event) {
      if (_disposed || !AppConfig.instance.isDriver) return;
      _ref.read(driverRideStatusRealtimeProvider.notifier).state = event;
    }, onError: _handleStreamError);

    _passengerLifecycleSub = _service.passengerRideLifecycleStream.listen((_) {
      if (_disposed || !AppConfig.instance.isPassenger) return;
      unawaited(_ref.read(bookingFlowProvider.notifier).hardRefreshStatus());
    }, onError: _handleStreamError);

    _newRideOfferSub = _service.newRideOfferStream.listen((_) {
      if (_disposed || !AppConfig.instance.isDriver) return;
      unawaited(_ref.read(driverHomeProvider.notifier).refreshHome());
    }, onError: _handleStreamError);

    _forceLogoutSub = _service.forceLogoutStream.listen((_) {
      if (_disposed) return;
      if (AppConfig.instance.isPassenger) {
        unawaited(_ref.read(passengerAuthProvider.notifier).logout());
      } else if (AppConfig.instance.isDriver) {
        unawaited(_ref.read(driverAuthProvider.notifier).logout());
      }
    }, onError: _handleStreamError);

    _tokenRefreshSub = AuthSessionNotifier.instance.tokenRefreshedEvents.listen(
      (_) => unawaited(_syncActiveAuth()),
      onError: _handleStreamError,
    );

    unawaited(_syncActiveAuth());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || state != AppLifecycleState.resumed) return;
    final health = _ref.read(realtimeHealthStateProvider);
    if (health != SocketHealthState.connected) {
      unawaited(_syncActiveAuth());
    }
  }

  Future<void> syncPassengerAuth(AuthState authState) async {
    if (_disposed || !AppConfig.instance.isPassenger) return;

    if (authState.status != AuthStatus.authenticated ||
        authState.userData == null) {
      await _service.disconnect();
      _joinedRideId = null;
      return;
    }

    final userId = _parsePassengerUserId(authState.userData!);
    if (userId == null) return;

    final token = await LocalStorage.instance.getSecure(
      AppConstants.accessTokenKey,
    );
    if (token == null || token.trim().isEmpty) return;

    try {
      await _service.connectPassenger(token: token, userId: userId);
    } catch (error, stackTrace) {
      _handleStreamError(error, stackTrace);
      return;
    }
    onActiveRideChanged(
      _ref.read(activeRideControllerProvider)?.rideId,
      force: true,
    );
  }

  Future<void> syncDriverAuth(AuthState authState) async {
    if (_disposed || !AppConfig.instance.isDriver) return;

    if (authState.status != AuthStatus.authenticated ||
        authState.userData == null) {
      await _service.disconnect();
      _joinedRideId = null;
      return;
    }

    final userId = _parseDriverUserId(authState.userData!);
    if (userId == null) return;

    final token = await LocalStorage.instance.getSecure(
      AppConstants.driverAccessTokenKey,
    );
    if (token == null || token.trim().isEmpty) return;

    try {
      await _service.connectDriver(token: token, userId: userId);
    } catch (error, stackTrace) {
      _handleStreamError(error, stackTrace);
      return;
    }
    onActiveRideChanged(
      _ref.read(driverHomeProvider).activeRide?.rideId,
      force: true,
    );
  }

  Future<void> _syncActiveAuth() async {
    if (AppConfig.instance.isPassenger) {
      await syncPassengerAuth(_ref.read(passengerAuthProvider));
    } else if (AppConfig.instance.isDriver) {
      await syncDriverAuth(_ref.read(driverAuthProvider));
    }
  }

  Future<void> forceReconnect() => _syncActiveAuth();

  void onActiveRideChanged(String? rideId, {bool force = false}) {
    if (_disposed) return;
    if (!AppConfig.instance.isPassenger && !AppConfig.instance.isDriver) return;
    final parsed = int.tryParse(rideId ?? '');
    if (parsed == null || parsed <= 0) {
      _joinedRideId = null;
      return;
    }
    if (!force && _joinedRideId == parsed) return;
    _joinedRideId = parsed;
    _service.joinRide(parsed);
  }

  int? _parsePassengerUserId(Map<String, dynamic> userData) {
    final raw = userData['id'] ?? userData['userId'] ?? userData['sub'];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  int? _parseDriverUserId(Map<String, dynamic> userData) {
    final raw = userData['driverId'] ?? userData['id'] ?? userData['userId'];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _healthSub?.cancel();
    _positionSub?.cancel();
    _rideAcceptedSub?.cancel();
    _driverRideStatusSub?.cancel();
    _passengerLifecycleSub?.cancel();
    _newRideOfferSub?.cancel();
    _forceLogoutSub?.cancel();
    _tokenRefreshSub?.cancel();
  }

  void _handleStreamError(Object error, StackTrace stackTrace) {
    logger.warning('Realtime session stream error', error, stackTrace);
    CrashReportingService.instance.recordNonFatal(error, stackTrace);
  }
}
