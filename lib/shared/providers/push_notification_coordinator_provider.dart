library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/utils/logger.dart';
import '../../domain/models/device_registration.dart';
import '../../domain/usecases/shared/deactivate_device_registration.dart';
import '../../domain/usecases/shared/sync_device_registration.dart';
import '../models/auth_state.dart';
import '../../features/driver/auth/providers/driver_auth_provider.dart';
import '../../features/passenger/auth/providers/passenger_auth_provider.dart';
import 'device_registration_provider.dart';
import 'push_notification_provider.dart';

final pushNotificationCoordinatorProvider = Provider<void>((ref) {
  final service = ref.watch(pushNotificationServiceProvider);
  final controller = _PushNotificationCoordinator(
    ref: ref,
    service: service,
    syncDeviceRegistration: ref.watch(syncDeviceRegistrationUseCaseProvider),
    deactivateDeviceRegistration: ref.watch(
      deactivateDeviceRegistrationUseCaseProvider,
    ),
    platformResolver: ref.watch(deviceRegistrationPlatformProvider),
  );

  ref.onDispose(controller.dispose);
  controller.initialize();

  if (AppConfig.instance.isPassenger) {
    ref.listen<AuthState>(passengerAuthProvider, (_, next) {
      controller.syncPassengerAuth(next);
    });
  } else if (AppConfig.instance.isDriver) {
    ref.listen<AuthState>(driverAuthProvider, (_, next) {
      controller.syncDriverAuth(next);
    });
  }
});

class _PushNotificationCoordinator {
  _PushNotificationCoordinator({
    required Ref ref,
    required PushNotificationService service,
    required SyncDeviceRegistrationUseCase syncDeviceRegistration,
    required DeactivateDeviceRegistrationUseCase deactivateDeviceRegistration,
    required DeviceRegistrationPlatformResolver platformResolver,
  }) : _ref = ref,
       _service = service,
       _syncDeviceRegistration = syncDeviceRegistration,
       _deactivateDeviceRegistration = deactivateDeviceRegistration,
       _platformResolver = platformResolver;

  final Ref _ref;
  final PushNotificationService _service;
  final SyncDeviceRegistrationUseCase _syncDeviceRegistration;
  final DeactivateDeviceRegistrationUseCase _deactivateDeviceRegistration;
  final DeviceRegistrationPlatformResolver _platformResolver;

  StreamSubscription<String>? _subscriptionSub;
  String? _latestSubscriptionId;
  String? _currentExternalId;
  bool _disposed = false;
  Future<void> _syncQueue = Future<void>.value();

  void initialize() {
    _subscriptionSub = _service.onSubscriptionChanged.listen((id) {
      if (_disposed) return;
      _latestSubscriptionId = id;
      logger.warning(
        'Diagnostic OneSignal [coordinator.subscription]: '
        'subscriptionId=${_maskValue(id)}',
      );
      _enqueueSyncCurrentAuth();
    });

    if (AppConfig.instance.isPassenger) {
      _enqueueSyncPassengerAuth(_ref.read(passengerAuthProvider));
    } else if (AppConfig.instance.isDriver) {
      _enqueueSyncDriverAuth(_ref.read(driverAuthProvider));
    }
  }

  void syncPassengerAuth(AuthState authState) {
    _enqueueSyncPassengerAuth(authState);
  }

  void syncDriverAuth(AuthState authState) {
    _enqueueSyncDriverAuth(authState);
  }

  void _enqueueSyncPassengerAuth(AuthState authState) {
    _enqueueSync(() => _syncPassengerAuth(authState));
  }

  void _enqueueSyncDriverAuth(AuthState authState) {
    _enqueueSync(() => _syncDriverAuth(authState));
  }

  void _enqueueSyncCurrentAuth() {
    if (AppConfig.instance.isPassenger) {
      _enqueueSyncPassengerAuth(_ref.read(passengerAuthProvider));
    } else if (AppConfig.instance.isDriver) {
      _enqueueSyncDriverAuth(_ref.read(driverAuthProvider));
    }
  }

  void _enqueueSync(Future<void> Function() action) {
    _syncQueue = _syncQueue
        .then((_) async {
          if (_disposed) return;
          await action();
        })
        .catchError((Object error, StackTrace stackTrace) {
          logger.warning(
            'Synchronisation push/device ignoree.',
            error,
            stackTrace,
          );
        });
  }

  Future<void> _syncPassengerAuth(AuthState authState) async {
    if (_disposed || !AppConfig.instance.isPassenger) return;
    final externalId = _parsePassengerExternalId(authState.userData);
    await _syncAuthState(
      authState: authState,
      externalId: externalId,
      role: 'PASSENGER',
    );
  }

  Future<void> _syncDriverAuth(AuthState authState) async {
    if (_disposed || !AppConfig.instance.isDriver) return;
    final externalId = _parseDriverExternalId(authState.userData);
    await _syncAuthState(
      authState: authState,
      externalId: externalId,
      role: 'DRIVER',
    );
  }

  Future<void> _syncAuthState({
    required AuthState authState,
    required String? externalId,
    required String role,
  }) async {
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    if (!isAuthenticated || externalId == null || externalId.isEmpty) {
      if (_currentExternalId == null) return;
      await _deactivateLastRegistration();
      await _service.logoutUser();
      _currentExternalId = null;
      return;
    }

    await _service.init();
    if (_disposed) return;

    if (_currentExternalId != null && _currentExternalId != externalId) {
      await _deactivateLastRegistration();
    }

    if (_currentExternalId != externalId) {
      await _service.loginUser(externalId);
      _currentExternalId = externalId;
    }

    if (!_service.hasNotificationPermission) {
      await _service.requestPermission();
    }
    if (_service.hasNotificationPermission &&
        !_service.isPushSubscriptionOptedIn) {
      await _service.optInUser();
      logger.warning(
        'Diagnostic OneSignal [coordinator.optIn.after]: '
        'permission=${_service.hasNotificationPermission}, '
        'optedIn=${_service.isPushSubscriptionOptedIn}, '
        'subscriptionId=${_maskValue(_service.currentSubscriptionId)}',
      );
    }

    final currentSubscriptionId = _service.currentSubscriptionId;
    if (currentSubscriptionId != null && currentSubscriptionId.isNotEmpty) {
      _latestSubscriptionId = currentSubscriptionId;
    }

    if (_latestSubscriptionId != null) {
      logger.warning(
        'Diagnostic OneSignal [coordinator.cachedSubscription]: '
        'subscriptionId=${_maskValue(_latestSubscriptionId)}',
      );
    }

    await _registerDevice(
      userId: externalId,
      role: role,
      subscriptionId: _latestSubscriptionId,
    );
  }

  Future<void> _registerDevice({
    required String userId,
    required String role,
    required String? subscriptionId,
  }) async {
    final trimmedSubscriptionId = subscriptionId?.trim();
    if (trimmedSubscriptionId == null || trimmedSubscriptionId.isEmpty) {
      return;
    }

    final platform = _platformResolver();
    if (platform == null || platform.trim().isEmpty) {
      logger.warning('Enregistrement device ignore: plateforme non supportee.');
      return;
    }

    final result = await _syncDeviceRegistration(
      DeviceRegistration(
        userId: userId,
        role: role,
        oneSignalSubscriptionId: trimmedSubscriptionId,
        platform: platform,
      ),
    );
    result.fold(
      (failure) => logger.warning(
        'Enregistrement device backend ignore: ${failure.message}',
      ),
      (_) {},
    );
  }

  Future<void> _deactivateLastRegistration() async {
    final result = await _deactivateDeviceRegistration.callLastRegistration();
    result.fold(
      (failure) => logger.warning(
        'Desactivation device backend ignoree: ${failure.message}',
      ),
      (_) {},
    );
  }

  String? _parsePassengerExternalId(Map<String, dynamic>? userData) {
    if (userData == null) return null;
    return (userData['id'] ?? userData['userId'] ?? userData['sub'])
        ?.toString();
  }

  String? _parseDriverExternalId(Map<String, dynamic>? userData) {
    if (userData == null) return null;
    return (userData['driverId'] ?? userData['id'] ?? userData['userId'])
        ?.toString();
  }

  void dispose() {
    _disposed = true;
    _subscriptionSub?.cancel();
  }

  String _maskValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'absent';
    if (trimmed.length <= 4) return 'present(len=${trimmed.length})';

    return '${trimmed.substring(0, 2)}...'
        '${trimmed.substring(trimmed.length - 2)}'
        '(len=${trimmed.length})';
  }
}
