/// Abstraction du stockage local.
///
/// Fournit un accès unifié à SharedPreferences (données non sensibles)
/// et FlutterSecureStorage (tokens, données sensibles).
library;

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/logger.dart';

class LocalStorage {
  LocalStorage._();

  static final LocalStorage _instance = LocalStorage._();
  static LocalStorage get instance => _instance;

  late SharedPreferences _prefs;

  /// Instance unique de stockage sécurisé partagée par toute l'app
  /// (y compris [ApiClient]) pour garantir des options identiques.
  ///
  /// `first_unlock` autorise l'accès en arrière-plan sur iOS. Sur Android,
  /// le backend chiffré par défaut (v10+) remplace l'ancien KeyStore
  /// par-valeur ; la robustesse face aux échecs de déchiffrement est
  /// assurée par [getSecure] (récupération gracieuse).
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  bool get isInitialized {
    try {
      _prefs;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Initialise SharedPreferences. À appeler avant runApp.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ──────────────────────────────────────────
  //  SharedPreferences (non sensible)
  // ──────────────────────────────────────────

  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  List<String>? getStringList(String key) => _prefs.getStringList(key);
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  bool? getBool(String key) => _prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();

  // ──────────────────────────────────────────
  //  SecureStorage (tokens, données sensibles)
  // ──────────────────────────────────────────

  /// Lit une valeur sécurisée avec récupération gracieuse.
  ///
  /// Si le déchiffrement échoue (KeyStore corrompu sur certains appareils),
  /// purge le coffre et renvoie `null` afin que l'utilisateur soit renvoyé
  /// proprement au login au lieu de rester bloqué.
  Future<String?> getSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } on PlatformException catch (error, stackTrace) {
      logger.warning(
        'SecureStorage illisible ($key) — reset',
        error,
        stackTrace,
      );
      await clearSecure();
      return null;
    }
  }

  Future<void> setSecure(String key, String value) =>
      _secureStorage.write(key: key, value: value);
  Future<void> deleteSecure(String key) => _secureStorage.delete(key: key);
  Future<void> clearSecure() async {
    try {
      await _secureStorage.deleteAll();
    } on PlatformException catch (error, stackTrace) {
      logger.warning('SecureStorage clear échoué', error, stackTrace);
    }
  }
}
