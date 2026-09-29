import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fraya_mobile/app.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';

void main() {
  // Désactive Google Fonts pour les tests
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('FrayaApp renders without error and shows login', (WidgetTester tester) async {
    // Initialisation
    AppConfig.instance.init(flavor: AppFlavor.dev);
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();

    // Build l'app
    await tester.pumpWidget(
      const ProviderScope(child: FrayaApp()),
    );

    // Stabilise quelques frames sans attendre indéfiniment.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
