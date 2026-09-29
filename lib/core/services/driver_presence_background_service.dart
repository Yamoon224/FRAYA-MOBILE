library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/logger.dart';

abstract interface class DriverPresenceBackgroundService {
  Future<void> start();

  Future<void> stop();
}

class PlatformDriverPresenceBackgroundService
    implements DriverPresenceBackgroundService {
  static const MethodChannel _channel = MethodChannel(
    'fraya_mobile/driver_presence',
  );

  @override
  Future<void> start() => _invokeAndroid('start');

  @override
  Future<void> stop() => _invokeAndroid('stop');

  Future<void> _invokeAndroid(String method) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException catch (error, stackTrace) {
      logger.warning(
        'Service de présence chauffeur indisponible: $method',
        error,
        stackTrace,
      );
    } on MissingPluginException catch (error, stackTrace) {
      logger.warning(
        'Canal natif de présence chauffeur absent: $method',
        error,
        stackTrace,
      );
    }
  }
}
