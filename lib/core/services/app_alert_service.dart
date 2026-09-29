library;

import 'dart:async';

enum AppAlertType { info, success, error }

class AppAlertMessage {
  const AppAlertMessage({
    required this.message,
    required this.type,
    required this.duration,
    required this.atTop,
  });

  final String message;
  final AppAlertType type;
  final Duration duration;
  final bool atTop;
}

class AppAlertService {
  AppAlertService._();

  static final AppAlertService instance = AppAlertService._();

  final StreamController<AppAlertMessage> _controller =
      StreamController<AppAlertMessage>.broadcast();

  Stream<AppAlertMessage> get alerts => _controller.stream;

  void showInfo(
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool atTop = true,
  }) {
    _controller.add(
      AppAlertMessage(
        message: message,
        type: AppAlertType.info,
        duration: duration,
        atTop: atTop,
      ),
    );
  }
}
