import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/directions_models.dart';
import 'package:fraya_mobile/core/services/navigation_progress.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Environ 111 m par 0,001° de latitude.
const _a = LatLng(5.3000, -4.0000);
const _b = LatLng(5.3050, -4.0000); // ~556 m au nord de A
const _c = LatLng(5.3050, -3.9950); // ~553 m à l'est de B

NavigationStep _step(
  LatLng start,
  LatLng end, {
  String maneuver = '',
  int meters = 0,
  int seconds = 0,
}) {
  return NavigationStep(
    instruction: 'Étape',
    distanceMeters: meters,
    durationSeconds: seconds,
    maneuver: maneuver,
    start: start,
    end: end,
  );
}

DirectionsRoute _route() {
  return DirectionsRoute(
    encodedPolyline: '',
    distanceText: '',
    distanceValue: 1100,
    durationText: '',
    durationValue: 200,
    arrivalTime: null,
    durationInTrafficValue: null,
    trafficSegments: const [],
    hasTrafficData: false,
    steps: [
      _step(_a, _b, meters: 556, seconds: 100),
      _step(_b, _c, maneuver: 'turn-right', meters: 553, seconds: 100),
    ],
  );
}

void main() {
  group('NavigationStep', () {
    test('retire le HTML de Google et garde un texte lisible', () {
      final step = NavigationStep.fromGoogleApi({
        'html_instructions':
            'Tournez à <b>droite</b> sur <b>Bd&nbsp;Latrille</b><div style="font-size:0.9em">Passage à niveau</div>',
        'distance': {'value': 120},
        'duration': {'value': 30},
        'maneuver': 'turn-right',
        'start_location': {'lat': 5.3, 'lng': -4.0},
        'end_location': {'lat': 5.301, 'lng': -4.0},
      });

      expect(
        step.instruction,
        'Tournez à droite sur Bd Latrille Passage à niveau',
      );
      expect(step.distanceMeters, 120);
      expect(step.maneuver, 'turn-right');
      expect(step.getPolylinePoints(), [step.start, step.end]);
    });

    test(
      "DirectionsRoute.fromGoogleApi lit les manoeuvres de la première étape de l'itinéraire",
      () {
        final route = DirectionsRoute.fromGoogleApi({
          'overview_polyline': {'points': ''},
          'legs': [
            {
              'steps': [
                {
                  'html_instructions': 'Continuez',
                  'distance': {'value': 10},
                  'duration': {'value': 5},
                  'start_location': {'lat': 1.0, 'lng': 2.0},
                  'end_location': {'lat': 1.1, 'lng': 2.1},
                },
              ],
            },
          ],
        });

        expect(route.steps, hasLength(1));
        expect(route.copyWith(hasTrafficData: true).steps, hasLength(1));
      },
    );
  });

  group('NavigationProgress.compute', () {
    test('sur la première manoeuvre, donne la distance jusqu\'au virage', () {
      final progress = NavigationProgress.compute(
        _route(),
        const LatLng(5.3020, -4.0000),
      )!;

      expect(progress.stepIndex, 0);
      expect(progress.distanceToManeuverMeters, closeTo(334, 10));
      expect(progress.isOffRoute, isFalse);
      expect(progress.hasArrived, isFalse);
      expect(progress.remainingMeters, closeTo(334 + 553, 10));
    });

    test('passe à la manoeuvre suivante après le virage', () {
      final progress = NavigationProgress.compute(
        _route(),
        const LatLng(5.3050, -3.9990),
        minStepIndex: 0,
      )!;

      expect(progress.stepIndex, 1);
      expect(progress.distanceToManeuverMeters, closeTo(445, 10));
    });

    test('ne revient pas en arrière grâce à minStepIndex', () {
      final progress = NavigationProgress.compute(
        _route(),
        const LatLng(5.3040, -4.0000),
        minStepIndex: 1,
      )!;

      expect(progress.stepIndex, 1);
    });

    test('détecte une sortie d\'itinéraire', () {
      final progress = NavigationProgress.compute(
        _route(),
        const LatLng(5.3020, -3.9900),
      )!;

      expect(progress.isOffRoute, isTrue);
      expect(
        progress.distanceFromRouteMeters,
        greaterThan(offRouteThresholdMeters),
      );
    });

    test(
      'signale l\'arrivée près de la destination, sur la dernière manoeuvre',
      () {
        final progress = NavigationProgress.compute(
          _route(),
          const LatLng(5.30502, -3.99503),
          minStepIndex: 1,
        )!;

        expect(progress.hasArrived, isTrue);
      },
    );

    test('retourne null quand l\'itinéraire n\'a pas de manoeuvres', () {
      expect(NavigationProgress.compute(DirectionsRoute.empty(), _a), isNull);
    });
  });

  group('formatage', () {
    test('distances', () {
      expect(formatNavigationDistance(42), '40 m');
      expect(formatNavigationDistance(340), '350 m');
      expect(formatNavigationDistance(1234), '1,2 km');
      expect(formatNavigationDistance(15400), '15 km');
    });

    test('durées', () {
      expect(formatNavigationDuration(20), '1 min');
      expect(formatNavigationDuration(600), '10 min');
      expect(formatNavigationDuration(3900), '1 h 05');
      expect(formatNavigationDuration(7200), '2 h');
    });
  });
}
