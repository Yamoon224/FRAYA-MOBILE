import 'dart:async';
import '../../../../core/utils/logger.dart';

mixin BookingPollingMixin {
  Timer? pollingTimer;
  bool isRefreshing = false;
  final log = AppLogger.instance;

  void stopPolling() {
    pollingTimer?.cancel();
    pollingTimer = null;
    isRefreshing = false;
  }

  int _pollTick = 0;

  /// Nombre de battements de 4 s entre deux relectures. 1 par défaut ; à surcharger pour espacer le
  /// sondage quand le temps réel prend le relais (forfait data limité).
  int get pollEveryTicks => 1;

  void startPolling(Future<void> Function() onPoll) {
    stopPolling();
    _pollTick = 0;
    pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pollTick++;
      if (_pollTick < pollEveryTicks) return;
      _pollTick = 0;
      onPoll();
    });
  }
}
