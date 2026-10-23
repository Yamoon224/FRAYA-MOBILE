/// Choix du conducteur : voix du guidage active ou coupée, conservé d'une navigation à l'autre.
library;

import '../../data/sources/local_storage.dart';

class NavigationVoicePreference {
  const NavigationVoicePreference._();

  static const String storageKey = 'navigation_voice_enabled';

  /// La voix est active tant que le conducteur ne l'a pas coupée.
  static bool get isEnabled {
    try {
      return LocalStorage.instance.getBool(storageKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> save(bool enabled) async {
    try {
      await LocalStorage.instance.setBool(storageKey, enabled);
    } catch (_) {
      // Stockage indisponible : le choix vaut pour la navigation en cours seulement.
    }
  }
}
