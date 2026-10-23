import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/directions_models.dart';
import 'package:fraya_mobile/core/services/navigation_progress.dart';
import 'package:fraya_mobile/core/services/navigation_voice.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _FakeSpeaker implements VoiceSpeaker {
  final spoken = <String>[];
  bool stopped = false;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stopped = true;
}

NavigationStep _step(String instruction, {String maneuver = ''}) =>
    NavigationStep(
      instruction: instruction,
      distanceMeters: 500,
      durationSeconds: 60,
      maneuver: maneuver,
      start: const LatLng(5.3, -4.0),
      end: const LatLng(5.31, -4.0),
    );

DirectionsRoute _route() => DirectionsRoute(
  encodedPolyline: '',
  distanceText: '',
  distanceValue: 1500,
  durationText: '',
  durationValue: 180,
  arrivalTime: null,
  durationInTrafficValue: null,
  trafficSegments: const [],
  hasTrafficData: false,
  steps: [
    _step('Partez vers le nord'),
    _step('Tournez à droite sur Bd Latrille', maneuver: 'turn-right'),
    _step('Continuez tout droit'),
  ],
);

NavigationProgress _progress(
  int index,
  double distance, {
  bool arrived = false,
}) => NavigationProgress(
  stepIndex: index,
  distanceToManeuverMeters: distance,
  remainingMeters: distance,
  remainingSeconds: 60,
  distanceFromRouteMeters: 0,
  isOffRoute: false,
  hasArrived: arrived,
);

void main() {
  group('spokenDistance', () {
    test('dit les mètres arrondis et les kilomètres', () {
      expect(spokenDistance(42), '40 mètres');
      expect(spokenDistance(5), '10 mètres');
      expect(spokenDistance(340), '350 mètres');
      expect(spokenDistance(1200), '1,2 kilomètre');
      expect(spokenDistance(2500), '2,5 kilomètres');
      expect(spokenDistance(15400), '15 kilomètres');
    });
  });

  group('NavigationVoiceGuide', () {
    test(
      "annonce la prochaine manoeuvre à distance, à l'approche puis au virage, une fois chacune",
      () {
        final speaker = _FakeSpeaker();
        final guide = NavigationVoiceGuide(speaker);
        final route = _route();

        guide.onProgress(route, _progress(0, 800), toPickup: false);
        guide.onProgress(
          route,
          _progress(0, 700),
          toPickup: false,
        ); // déjà annoncé
        guide.onProgress(
          route,
          _progress(0, 300),
          toPickup: false,
        ); // entre 250 et 400 : rien
        guide.onProgress(route, _progress(0, 200), toPickup: false);
        guide.onProgress(
          route,
          _progress(0, 190),
          toPickup: false,
        ); // déjà annoncé
        guide.onProgress(route, _progress(0, 30), toPickup: false);

        expect(speaker.spoken, [
          'Dans 800 mètres, Tournez à droite sur Bd Latrille',
          'Dans 200 mètres, Tournez à droite sur Bd Latrille',
          'Tournez à droite sur Bd Latrille',
        ]);
      },
    );

    test(
      "saute l'annonce lointaine quand on découvre déjà la manoeuvre de près",
      () {
        final speaker = _FakeSpeaker();
        final guide = NavigationVoiceGuide(speaker);

        guide.onProgress(_route(), _progress(1, 150), toPickup: false);

        expect(speaker.spoken, ['Dans 150 mètres, Continuez tout droit']);
      },
    );

    test("annonce l'arrivée selon la destination, une seule fois", () {
      final speaker = _FakeSpeaker();
      final guide = NavigationVoiceGuide(speaker);

      guide.onProgress(
        _route(),
        _progress(2, 10, arrived: true),
        toPickup: true,
      );
      guide.onProgress(
        _route(),
        _progress(2, 5, arrived: true),
        toPickup: true,
      );

      expect(speaker.spoken, ['Vous êtes arrivé chez le passager']);
    });

    test('annonce le dernier tronçon comme une arrivée', () {
      final speaker = _FakeSpeaker();
      final guide = NavigationVoiceGuide(speaker);

      guide.onProgress(_route(), _progress(2, 600), toPickup: false);

      expect(speaker.spoken, ['Dans 600 mètres, vous arrivez à destination']);
    });

    test('se tait quand la voix est coupée', () {
      final speaker = _FakeSpeaker();
      final guide = NavigationVoiceGuide(speaker)..enabled = false;

      guide.onProgress(_route(), _progress(0, 800), toPickup: false);
      guide.announceReroute();

      expect(speaker.spoken, isEmpty);
    });

    test(
      'annonce le recalcul puis repart de zéro pour le nouvel itinéraire',
      () {
        final speaker = _FakeSpeaker();
        final guide = NavigationVoiceGuide(speaker);
        final route = _route();

        guide.onProgress(route, _progress(0, 800), toPickup: false);
        guide.announceReroute();
        guide.onProgress(route, _progress(0, 800), toPickup: false);

        expect(speaker.spoken, [
          'Dans 800 mètres, Tournez à droite sur Bd Latrille',
          "Recalcul de l'itinéraire",
          'Dans 800 mètres, Tournez à droite sur Bd Latrille',
        ]);
      },
    );
  });
}
