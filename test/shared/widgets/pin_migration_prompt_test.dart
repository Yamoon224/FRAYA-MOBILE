import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/pin_migration_service.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/shared/widgets/pin_migration_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _alreadyPin = "Non, j'ai déjà 4 chiffres";

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          captured = context;
          return const Scaffold();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  late PinMigrationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.instance.init();
    service = PinMigrationService();
    resetPinMigrationPromptSession();
  });

  testWidgets('session ouverte avant la mise à jour : on demande quel mot de passe est utilisé', (tester) async {
    final context = await _pumpHost(tester);

    final future = maybeShowPinMigrationPrompt(context, onAccept: () {}, service: service);
    await tester.pumpAndSettle();

    expect(find.text('Mot de passe à 4 chiffres'), findsOneWidget);
    expect(find.textContaining('Utilisez-vous toujours votre ancien mot de passe'), findsOneWidget);
    expect(find.text(_alreadyPin), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    await future;
  });

  testWidgets('ancien mot de passe connu : invitation directe, sans question', (tester) async {
    await service.recordLogin('Secret123');
    final context = await _pumpHost(tester);

    final future = maybeShowPinMigrationPrompt(context, onAccept: () {}, service: service);
    await tester.pumpAndSettle();

    expect(find.textContaining('Vous utilisez encore votre ancien mot de passe'), findsOneWidget);
    expect(find.text(_alreadyPin), findsNothing);
    expect(find.text('Passer à 4 chiffres'), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    await future;
  });

  testWidgets('Oui ouvre le changement de mot de passe, la question reviendra si on abandonne', (tester) async {
    var accepted = 0;
    final context = await _pumpHost(tester);

    final future = maybeShowPinMigrationPrompt(context, onAccept: () => accepted++, service: service);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oui, passer à 4 chiffres'));
    await tester.pumpAndSettle();
    await future;

    expect(accepted, 1);
    expect(service.shouldPrompt(), isFalse);
  });

  testWidgets('Non, déjà 4 chiffres : plus jamais d invitation', (tester) async {
    final context = await _pumpHost(tester);

    final future = maybeShowPinMigrationPrompt(context, onAccept: () {}, service: service);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_alreadyPin));
    await tester.pumpAndSettle();
    await future;

    expect(service.status, PinMigrationStatus.done);
    expect(service.shouldPrompt(), isFalse);
  });

  testWidgets('une seule invitation par lancement', (tester) async {
    final context = await _pumpHost(tester);

    final first = maybeShowPinMigrationPrompt(context, onAccept: () {}, service: service);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    await first;
    await service.recordLogin('Secret123');

    await maybeShowPinMigrationPrompt(context, onAccept: () {}, service: service);
    await tester.pumpAndSettle();

    expect(find.text('Mot de passe à 4 chiffres'), findsNothing);
  });

  testWidgets('aucune invitation pour un compte déjà à 4 chiffres', (tester) async {
    await service.recordLogin('4821');
    final context = await _pumpHost(tester);

    await maybeShowPinMigrationPrompt(context, onAccept: () {}, service: service);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
