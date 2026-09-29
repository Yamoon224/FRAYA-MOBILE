library;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  CrashReportingService._();

  static final CrashReportingService instance = CrashReportingService._();

  bool _enabled = false;

  Future<void> enable() async {
    _enabled = true;
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }

  void recordFlutterError(FlutterErrorDetails details) {
    if (!_enabled) return;
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  }

  void recordFatal(Object error, StackTrace stackTrace) {
    if (!_enabled) return;
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
  }

  void recordNonFatal(Object error, StackTrace stackTrace) {
    if (!_enabled) return;
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}
