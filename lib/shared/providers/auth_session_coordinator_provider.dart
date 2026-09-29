library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/services/auth_session_notifier.dart';
import '../../core/utils/logger.dart';
import '../../features/driver/auth/providers/driver_auth_provider.dart';
import '../../features/passenger/auth/providers/passenger_auth_provider.dart';

final authSessionCoordinatorProvider = Provider<void>((ref) {
  final coordinator = _AuthSessionCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  coordinator.initialize();
});

class _AuthSessionCoordinator {
  _AuthSessionCoordinator(this._ref);

  final Ref _ref;

  StreamSubscription<String?>? _expiredSub;
  bool _logoutInProgress = false;

  void initialize() {
    _expiredSub = AuthSessionNotifier.instance.events.listen((_) {
      unawaited(_logoutExpiredSession());
    }, onError: _handleError);
  }

  Future<void> _logoutExpiredSession() async {
    if (_logoutInProgress) return;
    _logoutInProgress = true;
    try {
      if (AppConfig.instance.isPassenger) {
        await _ref.read(passengerAuthProvider.notifier).logout();
      } else if (AppConfig.instance.isDriver) {
        await _ref.read(driverAuthProvider.notifier).logout();
      }
    } catch (error, stackTrace) {
      logger.warning('Logout session expiree impossible', error, stackTrace);
    } finally {
      _logoutInProgress = false;
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    logger.warning('Ecoute expiration session interrompue', error, stackTrace);
  }

  void dispose() {
    _expiredSub?.cancel();
  }
}
