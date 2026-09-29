import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/features/driver/settings/screens/driver_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.instance.init();
  });

  testWidgets('account deletion action opens confirmation dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DriverSettingsScreen())),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Supprimer mon compte'), 300);
    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer le compte ?'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Supprimer')).dy,
      lessThan(tester.getTopLeft(find.text('Annuler')).dy),
    );
  });
}
