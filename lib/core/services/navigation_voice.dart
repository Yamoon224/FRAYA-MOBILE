/// Narration vocale du guidage de secours construit avec l'API Directions : en français, ou en anglais quand
/// la voix française n'est pas installée sur le téléphone.
library;

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/directions_models.dart';
import 'navigation_progress.dart';

abstract class VoiceSpeaker {
  Future<void> speak(String text);
  Future<void> stop();
}

/// Langue de la voix et des consignes du guidage de secours.
enum VoiceLanguage {
  fr('fr-FR', 'fr'),
  en('en-US', 'en');

  const VoiceLanguage(this.ttsLocale, this.directionsLanguage);

  /// Langue demandée au moteur de synthèse vocale.
  final String ttsLocale;

  /// Langue demandée à l'API Directions pour le texte des consignes.
  final String directionsLanguage;
}

class FlutterTtsSpeaker implements VoiceSpeaker {
  FlutterTtsSpeaker() : _tts = FlutterTts();

  static const MethodChannel _channel = MethodChannel('fraya_mobile/tts');

  final FlutterTts _tts;
  VoiceLanguage _language = VoiceLanguage.fr;
  Future<void>? _ready;
  bool _languageReady = false;

  Future<void> _configure() async {
    final result = await _tts.setLanguage(_language.ttsLocale);
    _languageReady = result == 1 || result == true;
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1);
    await _tts.awaitSpeakCompletion(false);
  }

  /// Règle la langue de la voix ; vrai quand la voix de cette langue est installée et utilisable.
  Future<bool> useLanguage(VoiceLanguage language) async {
    _language = language;
    try {
      await (_ready = _configure());
    } catch (_) {
      _languageReady = false;
    }
    return _languageReady;
  }

  /// Vrai quand la voix française est installée (vérifié à nouveau à chaque appel).
  Future<bool> checkFrench() => useLanguage(VoiceLanguage.fr);

  /// Ouvre l'installation des données vocales françaises du téléphone (Android).
  static Future<void> openFrenchVoiceInstall() async {
    try {
      await _channel.invokeMethod<void>('installFrenchVoice');
    } catch (_) {
      // Pas d'écran d'installation sur cet appareil : l'utilisateur passe par les réglages du téléphone.
    }
  }

  @override
  Future<void> speak(String text) async {
    try {
      await (_ready ??= _configure());
      // Du français n'est jamais lu avec une voix anglaise ; l'anglais peut passer par la voix par défaut.
      if (!_languageReady && _language == VoiceLanguage.fr) return;
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Pas de moteur vocal sur l'appareil : le guidage écrit continue.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

/// « 300 mètres », « 1,2 kilomètre » : distance lue à voix haute.
String spokenDistance(
  double meters, {
  VoiceLanguage language = VoiceLanguage.fr,
}) {
  final english = language == VoiceLanguage.en;
  if (meters < 1000) {
    final rounded = meters < 100
        ? (meters / 10).round() * 10
        : (meters / 50).round() * 50;
    final value = math.max(rounded, 10);
    return english ? '$value meters' : '$value mètres';
  }
  final kilometers = meters / 1000;
  final fixed = kilometers.toStringAsFixed(kilometers < 10 ? 1 : 0);
  if (english) {
    return kilometers < 2 ? '$fixed kilometer' : '$fixed kilometers';
  }
  final text = fixed.replaceAll('.', ',');
  return kilometers < 2 ? '$text kilomètre' : '$text kilomètres';
}

/// Phrases fixes de la narration dans une langue.
class VoicePhrases {
  const VoicePhrases._({
    required this.reroute,
    required this.arrivedAtPickup,
    required this.arrivedAtDestination,
    required this.arrivingAtPickup,
    required this.arrivingAtDestination,
    required this.inDistance,
  });

  final String reroute;
  final String arrivedAtPickup;
  final String arrivedAtDestination;
  final String arrivingAtPickup;
  final String arrivingAtDestination;
  final String Function(String distance, String instruction) inDistance;

  static const fr = VoicePhrases._(
    reroute: "Recalcul de l'itinéraire",
    arrivedAtPickup: 'Vous êtes arrivé chez le passager',
    arrivedAtDestination: 'Vous êtes arrivé à destination',
    arrivingAtPickup: 'vous arrivez chez le passager',
    arrivingAtDestination: 'vous arrivez à destination',
    inDistance: _frenchInDistance,
  );

  static const en = VoicePhrases._(
    reroute: 'Recalculating route',
    arrivedAtPickup: 'You have arrived at the passenger',
    arrivedAtDestination: 'You have arrived at your destination',
    arrivingAtPickup: 'you are arriving at the passenger',
    arrivingAtDestination: 'you are arriving at your destination',
    inDistance: _englishInDistance,
  );

  static VoicePhrases of(VoiceLanguage language) =>
      language == VoiceLanguage.en ? en : fr;

  static String _frenchInDistance(String distance, String instruction) =>
      'Dans $distance, $instruction';

  static String _englishInDistance(String distance, String instruction) =>
      'In $distance, $instruction';
}

/// Décide quand lire les consignes : une annonce à distance, une à l'approche, une au virage.
class NavigationVoiceGuide {
  NavigationVoiceGuide(this._speaker);

  static const double farAnnouncementMeters = 400;
  static const double nearAnnouncementMeters = 250;
  static const double nowAnnouncementMeters = 40;

  final VoiceSpeaker _speaker;
  final Set<String> _announced = {};
  bool enabled = true;

  /// Langue des phrases fixes ; le texte des consignes vient déjà de l'API Directions dans cette langue.
  VoiceLanguage language = VoiceLanguage.fr;

  VoicePhrases get _phrases => VoicePhrases.of(language);

  /// À appeler quand l'itinéraire change (recalcul) : les annonces repartent de zéro.
  void reset() => _announced.clear();

  void announceReroute() {
    if (!enabled) return;
    _announced.clear();
    _speaker.speak(_phrases.reroute);
  }

  void onProgress(
    DirectionsRoute route,
    NavigationProgress progress, {
    required bool toPickup,
  }) {
    if (!enabled) return;
    if (progress.hasArrived) {
      _once(
        'arrived',
        toPickup ? _phrases.arrivedAtPickup : _phrases.arrivedAtDestination,
      );
      return;
    }

    final steps = route.steps;
    final index = progress.stepIndex;
    final next = index + 1 < steps.length ? steps[index + 1] : null;
    final instruction =
        next?.instruction ??
        (toPickup ? _phrases.arrivingAtPickup : _phrases.arrivingAtDestination);
    final distance = progress.distanceToManeuverMeters;
    final distanceText = spokenDistance(distance, language: language);

    if (distance <= nowAnnouncementMeters) {
      _once('now:$index', _capitalize(instruction));
    } else if (distance <= nearAnnouncementMeters) {
      _once('near:$index', _phrases.inDistance(distanceText, instruction));
    } else if (distance > farAnnouncementMeters) {
      _once('far:$index', _phrases.inDistance(distanceText, instruction));
    }
  }

  Future<void> dispose() => _speaker.stop();

  void _once(String key, String text) {
    if (!_announced.add(key)) return;
    _speaker.speak(text);
  }

  static String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
