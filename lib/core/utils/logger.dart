/// Logger structuré pour l'application.
///
/// Wrapper autour du package [logger] avec des niveaux de log
/// conditionnés par la configuration de l'app.
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logger/logger.dart' as log;

import '../config/app_config.dart';

class AppLogger {
  AppLogger._();

  static final AppLogger _instance = AppLogger._();
  static AppLogger get instance => _instance;

  late log.Logger _logger;

  log.Logger get _activeLogger {
    try {
      return _logger;
    } catch (_) {
      _logger = _createLogger(enableLogging: false);
      return _logger;
    }
  }

  /// Initialise le logger. À appeler après [AppConfig.init].
  void init() {
    _logger = _createLogger(
      enableLogging: AppConfig.instance.enableLogging || kDebugMode,
    );
  }

  log.Logger _createLogger({required bool enableLogging}) {
    return log.Logger(
      filter: log.ProductionFilter(),
      printer: log.PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        noBoxingByDefault: true,
      ),
      level: enableLogging ? log.Level.debug : log.Level.warning,
    );
  }

  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _activeLogger.d(message, error: error, stackTrace: stackTrace);
  }

  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _activeLogger.i(message, error: error, stackTrace: stackTrace);
  }

  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _activeLogger.w(message, error: error, stackTrace: stackTrace);
  }

  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _activeLogger.e(message, error: error, stackTrace: stackTrace);
  }

  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _activeLogger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// Raccourci global pour accéder au logger.
AppLogger get logger => AppLogger.instance;
