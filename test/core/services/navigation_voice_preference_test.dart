import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/navigation_voice_preference.dart';

void main() {
  test('la voix est active par défaut, même sans stockage disponible', () {
    expect(NavigationVoicePreference.isEnabled, isTrue);
  });

  test(
    'enregistrer le choix ne plante pas quand le stockage est indisponible',
    () async {
      await NavigationVoicePreference.save(false);
      await NavigationVoicePreference.save(true);
    },
  );
}
