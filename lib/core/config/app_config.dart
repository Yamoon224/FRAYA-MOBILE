/// Configuration de l'application selon le flavor actif.
///
/// Définit les paramètres globaux (nom, base URL, etc.) en fonction
/// du flavor sélectionné au lancement (Passenger, Driver, Dev).
library;

import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_flavor.dart';

class AppConfig {
  AppConfig._();

  static final AppConfig _instance = AppConfig._();
  static AppConfig get instance => _instance;

  late AppFlavor flavor;
  late String appName;
  late String baseUrl;
  late bool enableLogging;

  /// Initialise la configuration pour le [flavor] donné.
  void init({required AppFlavor flavor}) {
    this.flavor = flavor;

    switch (flavor) {
      case AppFlavor.passenger:
        appName = 'Fraya Taxi';
        baseUrl = Env.prodBaseUrl;
        enableLogging = false;
      case AppFlavor.driver:
        appName = 'Fraya Chauffeur';
        baseUrl = Env.prodBaseUrl;
        enableLogging = false;
      case AppFlavor.dev:
        appName = 'Fraya Dev';
        baseUrl = Env.devBaseUrl;
        enableLogging = true;
    }
  }

  bool get isPassenger => flavor == AppFlavor.passenger;
  bool get isDriver => flavor == AppFlavor.driver;
  bool get isDev => flavor == AppFlavor.dev;
  String get supportWhatsAppNumber => Env.supportWhatsAppNumber;
}

/// Variables d'environnement.
class Env {
  Env._();

  // static const String devBaseUrl = 'http://83.228.247.227/api/v1/fraya_taxi';
  // static const String stagingBaseUrl =
  //     'http://83.228.247.227/api/v1/fraya_taxi';
  // static const String prodBaseUrl = 'http://83.228.247.227/api/v1/fraya_taxi';

  // static const String drivesBaseUrl = 'http://83.228.247.227/drives';
  // static const String profilesBaseUrl = 'http://83.228.247.227/profiles';

  static const String devBaseUrl = 'http://83.228.247.227/api/v1/fraya_taxi';
  static const String stagingBaseUrl =
      'http://83.228.247.227/api/v1/fraya_taxi';
  static const String prodBaseUrl =
      'https://manager.frayataxi.ci/api/v1/fraya_taxi';

  static const String drivesBaseUrl = 'http://83.228.247.227/drives';
  static const String profilesBaseUrl = 'http://83.228.247.227/profiles';

  static String? resolveProfilePhotoUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim();
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final filename = v.contains('/') ? v.split('/').last : v;
    if (filename.isEmpty) return null;
    return '$profilesBaseUrl/$filename';
  }

  // Google Maps — lecture depuis .env selon la plateforme
  // ANCIEN CODE :
  // static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static String get googleMapsApiKey {
    if (Platform.isAndroid) {
      return dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? '';
    } else if (Platform.isIOS) {
      return dotenv.env['GOOGLE_MAPS_API_KEY_IOS'] ?? '';
    }
    return '';
  }

  static String get supportWhatsAppNumber {
    final value = dotenv.env['WHATSAPP_SUPPORT_NUMBER']?.trim() ?? '';
    return value;
  }
}
