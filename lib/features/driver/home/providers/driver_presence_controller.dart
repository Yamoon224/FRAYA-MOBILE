library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/driver_presence_background_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/usecases/driver/status/send_driver_heartbeat.dart';
import '../../../../domain/usecases/driver/status/update_driver_status.dart';
import '../../../../domain/usecases/usecase.dart';
import 'driver_home_provider.dart';
import 'driver_status_dependencies.dart';

final driverHeartbeatIntervalProvider = Provider<Duration>(
  (_) => const Duration(seconds: 30),
);

final driverPresenceBackgroundServiceProvider =
    Provider<DriverPresenceBackgroundService>((_) {
      return PlatformDriverPresenceBackgroundService();
    });

final driverPresenceControllerProvider = Provider<DriverPresenceController>((
  ref,
) {
  final controller = DriverPresenceController(
    sendHeartbeatUseCase: ref.watch(sendDriverHeartbeatUseCaseProvider),
    updateStatusUseCase: ref.watch(updateDriverStatusUseCaseProvider),
    backgroundService: ref.watch(driverPresenceBackgroundServiceProvider),
    heartbeatInterval: ref.watch(driverHeartbeatIntervalProvider),
  );

  unawaited(controller.syncOnline(ref.read(driverHomeProvider).isOnline));
  ref.listen(driverHomeProvider, (previous, next) {
    if (previous?.isOnline == next.isOnline) return;
    unawaited(controller.syncOnline(next.isOnline));
  });
  ref.onDispose(controller.dispose);
  return controller;
});

class DriverPresenceController {
  DriverPresenceController({
    required SendDriverHeartbeatUseCase sendHeartbeatUseCase,
    required UpdateDriverStatusUseCase updateStatusUseCase,
    required DriverPresenceBackgroundService backgroundService,
    required Duration heartbeatInterval,
  }) : _sendHeartbeatUseCase = sendHeartbeatUseCase,
       _updateStatusUseCase = updateStatusUseCase,
       _backgroundService = backgroundService,
       _heartbeatInterval = heartbeatInterval;

  final SendDriverHeartbeatUseCase _sendHeartbeatUseCase;
  final UpdateDriverStatusUseCase _updateStatusUseCase;
  final DriverPresenceBackgroundService _backgroundService;
  final Duration _heartbeatInterval;

  Timer? _heartbeatTimer;
  bool? _isOnline;
  bool _heartbeatInFlight = false;
  bool _requiresPoolReentry = false;
  bool _disposed = false;

  Future<void> syncOnline(bool isOnline) async {
    if (_disposed || _isOnline == isOnline) return;
    _isOnline = isOnline;
    if (!isOnline) {
      await _stopPresence();
      return;
    }

    await _backgroundService.start();
    _startTimer();
    await _sendPresenceSignal();
  }

  Future<void> handleAppResumed() async {
    if (_disposed || _isOnline != true) return;
    await _backgroundService.start();
    _startTimer();
    await _sendPresenceSignal(forcePoolReentry: true);
  }

  Future<void> handleAppDetached() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _backgroundService.stop();
  }

  void dispose() {
    _disposed = true;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    unawaited(_backgroundService.stop());
  }

  void _startTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      unawaited(_sendPresenceSignal());
    });
  }

  Future<void> _stopPresence() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _requiresPoolReentry = false;
    await _backgroundService.stop();
  }

  Future<void> _sendPresenceSignal({bool forcePoolReentry = false}) async {
    if (_disposed || _isOnline != true || _heartbeatInFlight) return;
    _heartbeatInFlight = true;
    try {
      if (forcePoolReentry || _requiresPoolReentry) {
        final reentered = await _reenterOnlinePool();
        if (!reentered) return;
      }
      final result = await _sendHeartbeatUseCase(const NoParams());
      result.fold((failure) {
        _requiresPoolReentry = true;
        logger.warning('Heartbeat chauffeur échoué: ${failure.message}');
      }, (_) => _requiresPoolReentry = false);
    } finally {
      _heartbeatInFlight = false;
    }
  }

  Future<bool> _reenterOnlinePool() async {
    final result = await _updateStatusUseCase(
      const UpdateDriverStatusParams(isOnline: true),
    );
    return result.fold(
      (failure) {
        _requiresPoolReentry = true;
        logger.warning(
          'Réactivation de la présence chauffeur échouée: ${failure.message}',
        );
        return false;
      },
      (_) {
        _requiresPoolReentry = false;
        return true;
      },
    );
  }
}
