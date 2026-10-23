import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/navigation_sdk_voice.dart';
import 'package:fraya_mobile/core/services/navigation_voice.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class _FakeSpeaker implements VoiceSpeaker {
  final spoken = <String>[];

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

StepInfo _step(
  Maneuver maneuver, {
  int number = 1,
  String? road,
  int? roundaboutTurn,
}) => StepInfo(
  distanceFromPrevStepMeters: 500,
  timeFromPrevStepSeconds: 60,
  drivingSide: DrivingSide.right,
  exitNumber: null,
  fullInstructions: 'Turn left onto Main Street',
  fullRoadName: road,
  simpleRoadName: road,
  roundaboutTurnNumber: roundaboutTurn,
  stepNumber: number,
  lanes: null,
  maneuver: maneuver,
  maneuverImage: null,
  lanesImage: null,
);

NavInfo _info(
  StepInfo? step,
  int? meters, {
  NavState state = NavState.enroute,
}) => NavInfo(
  currentStep: step,
  remainingSteps: const [],
  routeChanged: false,
  distanceToCurrentStepMeters: meters,
  distanceToFinalDestinationMeters: 2000,
  distanceToNextDestinationMeters: 2000,
  timeToCurrentStepSeconds: 30,
  timeToFinalDestinationSeconds: 300,
  timeToNextDestinationSeconds: 300,
  navState: state,
);

void main() {
  group('resolveVoiceMode', () {
    test('lit en français quand la voix française est installée', () {
      expect(
        resolveVoiceMode(userEnabled: true, frenchAvailable: true),
        SdkVoiceMode.french,
      );
    });

    test('laisse la voix du SDK (anglais) quand le français est absent', () {
      expect(
        resolveVoiceMode(userEnabled: true, frenchAvailable: false),
        SdkVoiceMode.sdkDefault,
      );
    });

    test(
      'se tait quand le conducteur a coupé la voix, quelle que soit la langue',
      () {
        expect(
          resolveVoiceMode(userEnabled: false, frenchAvailable: true),
          SdkVoiceMode.off,
        );
        expect(
          resolveVoiceMode(userEnabled: false, frenchAvailable: false),
          SdkVoiceMode.off,
        );
      },
    );
  });

  group('frenchManeuverPhrase', () {
    test('tourne et nomme la rue', () {
      expect(frenchManeuverPhrase(Maneuver.turnLeft), 'tournez à gauche');
      expect(
        frenchManeuverPhrase(
          Maneuver.turnRight,
          roadName: 'Boulevard Latrille',
        ),
        'tournez à droite sur Boulevard Latrille',
      );
      expect(
        frenchManeuverPhrase(Maneuver.turnSlightLeft),
        'tournez légèrement à gauche',
      );
      expect(
        frenchManeuverPhrase(Maneuver.turnSharpRight),
        'tournez franchement à droite',
      );
      expect(frenchManeuverPhrase(Maneuver.turnKeepLeft), 'serrez à gauche');
    });

    test('couvre demi-tour, rond-point, sortie, insertion et arrivée', () {
      expect(
        frenchManeuverPhrase(Maneuver.turnUTurnClockwise),
        'faites demi-tour',
      );
      expect(
        frenchManeuverPhrase(
          Maneuver.roundaboutClockwise,
          roundaboutTurnNumber: 2,
        ),
        'au rond-point, prenez la 2e sortie',
      );
      expect(
        frenchManeuverPhrase(
          Maneuver.roundaboutClockwise,
          roundaboutTurnNumber: 1,
        ),
        'au rond-point, prenez la 1re sortie',
      );
      expect(
        frenchManeuverPhrase(Maneuver.offRampRight),
        'prenez la sortie à droite',
      );
      expect(frenchManeuverPhrase(Maneuver.mergeLeft), 'insérez-vous à gauche');
      expect(
        frenchManeuverPhrase(Maneuver.destination),
        'vous arrivez à destination',
      );
      expect(
        frenchManeuverPhrase(Maneuver.destinationLeft),
        'votre destination est à gauche',
      );
      expect(frenchManeuverPhrase(Maneuver.straight), 'continuez tout droit');
    });

    test('ne contient aucun mot anglais courant', () {
      for (final maneuver in Maneuver.values) {
        final phrase = frenchManeuverPhrase(maneuver, roundaboutTurnNumber: 3);
        expect(
          phrase,
          isNot(
            matches(
              RegExp(
                r'\b(turn|left|right|exit|onto|continue)\b',
                caseSensitive: false,
              ),
            ),
          ),
          reason: maneuver.name,
        );
      }
    });
  });

  group('SdkFrenchVoiceGuide', () {
    test(
      'annonce à distance, à l approche puis au virage, une fois chacune',
      () {
        final speaker = _FakeSpeaker();
        final guide = SdkFrenchVoiceGuide(speaker);
        final step = _step(Maneuver.turnRight, road: 'Bd Latrille');

        guide.onNavInfo(_info(step, 800));
        guide.onNavInfo(_info(step, 700));
        guide.onNavInfo(_info(step, 300));
        guide.onNavInfo(_info(step, 200));
        guide.onNavInfo(_info(step, 190));
        guide.onNavInfo(_info(step, 30));

        expect(speaker.spoken, [
          'Dans 800 mètres, tournez à droite sur Bd Latrille',
          'Dans 200 mètres, tournez à droite sur Bd Latrille',
          'Tournez à droite sur Bd Latrille',
        ]);
      },
    );

    test('passe à la consigne suivante quand le numéro d étape change', () {
      final speaker = _FakeSpeaker();
      final guide = SdkFrenchVoiceGuide(speaker);

      guide.onNavInfo(_info(_step(Maneuver.turnLeft, number: 1), 20));
      guide.onNavInfo(_info(_step(Maneuver.turnRight, number: 2), 600));

      expect(speaker.spoken, [
        'Tournez à gauche',
        'Dans 600 mètres, tournez à droite',
      ]);
    });

    test('annonce l arrivée et le recalcul', () {
      final speaker = _FakeSpeaker();
      final guide = SdkFrenchVoiceGuide(speaker);

      guide.onNavInfo(_info(null, null, state: NavState.rerouting));
      guide.onNavInfo(_info(null, null, state: NavState.rerouting));
      guide.onNavInfo(_info(_step(Maneuver.destination, number: 9), 12));

      expect(speaker.spoken, [
        "Recalcul de l'itinéraire",
        'Vous êtes arrivé à destination',
      ]);
    });

    test('se tait quand la voix est coupée', () {
      final speaker = _FakeSpeaker();
      final guide = SdkFrenchVoiceGuide(speaker)..enabled = false;

      guide.onNavInfo(_info(_step(Maneuver.turnLeft), 800));

      expect(speaker.spoken, isEmpty);
    });
  });
}
