library;

import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../data/sources/api_client.dart';
import '../../data/sources/local_storage.dart';
import '../config/app_config.dart';
import '../config/app_flavor.dart';
import '../services/crash_reporting_service.dart';
import '../services/push_notification_service.dart';
import '../utils/logger.dart';

Future<void> runFrayaApp(AppFlavor flavor) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await _initializeRequiredServices(flavor);
      runApp(const ProviderScope(child: FrayaApp()));
      _scheduleDeferredServicesInitialization();
    },
    (error, stackTrace) {
      debugPrint('Erreur non geree: $error');
      CrashReportingService.instance.recordFatal(error, stackTrace);
    },
  );
}

Future<void> _initializeRequiredServices(AppFlavor flavor) async {
  await dotenv.load(fileName: '.env');
  AppConfig.instance.init(flavor: flavor);
  AppLogger.instance.init();
  logger.info('${AppConfig.instance.appName} initialise');
  await LocalStorage.instance.init();
  ApiClient.instance.init();
}

void _scheduleDeferredServicesInitialization() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializePushNotifications());
    unawaited(_initializeCrashReporting());
  });
}

Future<void> _initializePushNotifications() async {
  try {
    await PushNotificationService.instance.init();
  } catch (error, stackTrace) {
    logger.warning('OneSignal indisponible', error, stackTrace);
  }
}

Future<void> _initializeCrashReporting() async {
  try {
    await Firebase.initializeApp();
    await CrashReportingService.instance.enable();
    FlutterError.onError = CrashReportingService.instance.recordFlutterError;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      CrashReportingService.instance.recordFatal(error, stackTrace);
      return true;
    };
  } catch (error, stackTrace) {
    logger.warning('Crashlytics indisponible', error, stackTrace);
  }
}
