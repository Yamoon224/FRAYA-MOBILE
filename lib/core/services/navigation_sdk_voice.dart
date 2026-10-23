/// Narration vocale du Navigation SDK, toujours en français.
///
/// La voix intégrée du SDK suit la langue du téléphone et reste en anglais si les voix françaises ne sont pas
/// installées : on la coupe et on lit nous-mêmes les consignes, composées en français à partir des manoeuvres
/// du SDK et lues avec une voix française imposée.
library;

import 'package:google_navigation_flutter/google_navigation_flutter.dart';

import 'navigation_voice.dart';

String _side(String name) {
  if (name.contains('Left')) return 'à gauche';
  if (name.contains('Right')) return 'à droite';
  return '';
}

String _withSide(String phrase, String name) {
  final side = _side(name);
  return side.isEmpty ? phrase : '$phrase $side';
}

String _ordinal(int n) => n == 1 ? '1re' : '${n}e';

/// Consigne française d'une manoeuvre : « tournez à gauche », « au rond-point, prenez la 2e sortie »…
String frenchManeuverPhrase(
  Maneuver maneuver, {
  int? roundaboutTurnNumber,
  String? roadName,
}) {
  final name = maneuver.name;
  final road = roadName?.trim();
  final onRoad = (road == null || road.isEmpty) ? '' : ' sur $road';

  if (name == 'destination') return 'vous arrivez à destination';
  if (name == 'destinationLeft') return 'votre destination est à gauche';
  if (name == 'destinationRight') return 'votre destination est à droite';
  if (name == 'depart') return 'partez$onRoad';
  if (name == 'straight' || name == 'nameChange' || name == 'unknown') {
    return 'continuez tout droit$onRoad';
  }
  if (name.contains('UTurn')) return 'faites demi-tour';
  if (name.startsWith('roundaboutExit')) return 'quittez le rond-point$onRoad';
  if (name.startsWith('roundabout')) {
    final exit = roundaboutTurnNumber;
    return exit != null && exit > 0
        ? 'au rond-point, prenez la ${_ordinal(exit)} sortie$onRoad'
        : 'prenez le rond-point$onRoad';
  }
  if (name.startsWith('ferry')) return 'embarquez sur le ferry';
  if (name.startsWith('merge'))
    return 'insérez-vous${_side(name).isEmpty ? '' : ' ${_side(name)}'}$onRoad';
  if (name.startsWith('fork'))
    return '${_withSide('prenez la bifurcation', name)}$onRoad';
  if (name.startsWith('offRamp'))
    return '${_withSide('prenez la sortie', name)}$onRoad';
  if (name.startsWith('onRamp'))
    return '${_withSide('prenez la bretelle', name)}$onRoad';
  if (name.startsWith('turnKeep')) return '${_withSide('serrez', name)}$onRoad';
  if (name.startsWith('turnSlight'))
    return '${_withSide('tournez légèrement', name)}$onRoad';
  if (name.startsWith('turnSharp'))
    return '${_withSide('tournez franchement', name)}$onRoad';
  if (name.startsWith('turn')) return '${_withSide('tournez', name)}$onRoad';
  return 'continuez$onRoad';
}

/// Décide quand lire les consignes du SDK : à distance, à l'approche, au virage, au recalcul.
class SdkFrenchVoiceGuide {
  SdkFrenchVoiceGuide(this._speaker);

  static const double farAnnouncementMeters = 400;
  static const double nearAnnouncementMeters = 250;
  static const double nowAnnouncementMeters = 40;

  final VoiceSpeaker _speaker;
  final Set<String> _announced = {};
  bool enabled = true;
  bool _wasRerouting = false;

  void onNavInfo(NavInfo info) {
    if (!enabled) return;

    final rerouting = info.navState == NavState.rerouting;
    if (rerouting && !_wasRerouting) {
      _announced.clear();
      _speaker.speak("Recalcul de l'itinéraire");
    }
    _wasRerouting = rerouting;
    if (rerouting) return;

    final step = info.currentStep;
    final meters = info.distanceToCurrentStepMeters;
    if (step == null || meters == null) return;

    final phrase = frenchManeuverPhrase(
      step.maneuver,
      roundaboutTurnNumber: step.roundaboutTurnNumber,
      roadName: step.simpleRoadName ?? step.fullRoadName,
    );
    final isArrival = step.maneuver.name.startsWith('destination');
    final key = '${step.stepNumber}:${step.maneuver.name}';
    final distance = meters.toDouble();

    if (distance <= nowAnnouncementMeters) {
      _once(
        'now:$key',
        isArrival ? 'Vous êtes arrivé à destination' : _capitalize(phrase),
      );
    } else if (distance <= nearAnnouncementMeters) {
      _once('near:$key', 'Dans ${spokenDistance(distance)}, $phrase');
    } else if (distance > farAnnouncementMeters) {
      _once('far:$key', 'Dans ${spokenDistance(distance)}, $phrase');
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
