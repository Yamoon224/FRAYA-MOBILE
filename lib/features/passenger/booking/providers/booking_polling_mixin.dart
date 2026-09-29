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

  void startPolling(Future<void> Function() onPoll) {
    stopPolling();
    pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      onPoll();
    });
  }
}
