/// Narration vocale (en français) du guidage de secours construit avec l'API Directions.
library;

import 'dart:math' as math;

import 'package:flutter_tts/flutter_tts.dart';

import '../models/directions_models.dart';
import 'navigation_progress.dart';

abstract class VoiceSpeaker {
  Future<void> speak(String text);
  Future<void> stop();
}

class FlutterTtsSpeaker implements VoiceSpeaker {
  FlutterTtsSpeaker() : _tts = FlutterTts();

  final FlutterTts _tts;
  Future<void>? _ready;

  Future<void> _configure() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1);
    await _tts.awaitSpeakCompletion(false);
  }

  @override
  Future<void> speak(String text) async {
    try {
      await (_ready ??= _configure());
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
String spokenDistance(double meters) {
  if (meters < 1000) {
    final rounded = meters < 100
        ? (meters / 10).round() * 10
        : (meters / 50).round() * 50;
    final value = math.max(rounded, 10);
    return '$value mètres';
  }
  final kilometers = meters / 1000;
  final text = kilometers
      .toStringAsFixed(kilometers < 10 ? 1 : 0)
      .replaceAll('.', ',');
  return kilometers < 2 ? '$text kilomètre' : '$text kilomètres';
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

  /// À appeler quand l'itinéraire change (recalcul) : les annonces repartent de zéro.
  void reset() => _announced.clear();

  void announceReroute() {
    if (!enabled) return;
    _announced.clear();
    _speaker.speak("Recalcul de l'itinéraire");
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
        toPickup
            ? 'Vous êtes arrivé chez le passager'
            : 'Vous êtes arrivé à destination',
      );
      return;
    }

    final steps = route.steps;
    final index = progress.stepIndex;
    final next = index + 1 < steps.length ? steps[index + 1] : null;
    final instruction =
        next?.instruction ??
        (toPickup
            ? 'vous arrivez chez le passager'
            : 'vous arrivez à destination');
    final distance = progress.distanceToManeuverMeters;
    final distanceText = spokenDistance(distance);

    if (distance <= nowAnnouncementMeters) {
      _once('now:$index', _capitalize(instruction));
    } else if (distance <= nearAnnouncementMeters) {
      _once('near:$index', 'Dans $distanceText, $instruction');
    } else if (distance > farAnnouncementMeters) {
      _once('far:$index', 'Dans $distanceText, $instruction');
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
