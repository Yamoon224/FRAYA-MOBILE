library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/logger.dart';

/// Sur beaucoup de téléphones Android, l'optimisation de batterie arrête l'app en arrière-plan :
/// le chauffeur disparaît alors de la recherche. Ce service permet de le guider vers les réglages.
abstract interface class BatteryOptimizationService {
  /// `true` si l'app est déjà exemptée (ou si la plateforme n'est pas concernée).
  Future<bool> isIgnoringOptimizations();

  Future<bool> openSettings();
}

class PlatformBatteryOptimizationService implements BatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel(
    'fraya_mobile/driver_presence',
  );

  @override
  Future<bool> isIgnoringOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
          true;
    } on PlatformException catch (error, stackTrace) {
      logger.warning('Lecture optimisation batterie impossible', error, stackTrace);
      return true;
    } on MissingPluginException {
      return true;
    }
  }

  @override
  Future<bool> openSettings() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('openBatteryOptimizationSettings') ??
          false;
    } on PlatformException catch (error, stackTrace) {
      logger.warning('Ouverture réglages batterie impossible', error, stackTrace);
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
