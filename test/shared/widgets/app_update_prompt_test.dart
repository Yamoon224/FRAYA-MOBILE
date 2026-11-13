import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/app_update_service.dart';
import 'package:fraya_mobile/shared/widgets/app_update_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUpdates extends AppUpdateService {
  _FakeUpdates(this.update);

  final AvailableUpdate? update;
  int checks = 0;
  int started = 0;
  int snoozed = 0;

  @override
  Future<AvailableUpdate?> check() async {
    checks++;
    return update;
  }

  @override
  Future<void> startUpdate(AvailableUpdate update) async => started++;

  @override
  Future<void> snooze(AvailableUpdate update, {DateTime? now}) async {
    snoozed++;
    await super.snooze(update, now: now);
  }
}

void main() {
  const update = AvailableUpdate(storeVersion: '1.0.7');
  final t0 = DateTime(2026, 11, 13, 10);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetAppUpdatePromptSession();
  });

  Future<BuildContext> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    return tester.element(find.byType(SizedBox));
  }

  testWidgets(
    'affiche la boîte « Mise à jour disponible » et lance la mise à jour',
    (tester) async {
      final context = await pumpApp(tester);
      final service = _FakeUpdates(update);

      final future = maybeShowAppUpdatePrompt(
        () => context,
        service: service,
        now: t0,
      );
      await tester.pumpAndSettle();
      expect(find.text('Mise à jour disponible'), findsOneWidget);
      expect(find.textContaining('1.0.7'), findsOneWidget);

      await tester.tap(find.text('Mettre à jour'));
      await tester.pumpAndSettle();

      expect(await future, isTrue);
      expect(service.started, 1);
    },
  );

  testWidgets(
    '« Plus tard » repousse 24 h puis la boîte revient sans relancer l\'app',
    (tester) async {
      final context = await pumpApp(tester);
      final service = _FakeUpdates(update);

      var future = maybeShowAppUpdatePrompt(
        () => context,
        service: service,
        now: t0,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plus tard'));
      await tester.pumpAndSettle();
      await future;
      expect(service.snoozed, 1);

      // Retour au premier plan 2 h plus tard : repoussé, pas de boîte.
      future = maybeShowAppUpdatePrompt(
        () => context,
        service: service,
        now: t0.add(const Duration(hours: 2)),
      );
      await tester.pumpAndSettle();
      await future;
      expect(find.text('Mise à jour disponible'), findsNothing);

      // 25 h plus tard : la même version est reproposée.
      future = maybeShowAppUpdatePrompt(
        () => context,
        service: service,
        now: t0.add(const Duration(hours: 25)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mise à jour disponible'), findsOneWidget);
      await tester.tap(find.text('Plus tard'));
      await tester.pumpAndSettle();
      await future;
    },
  );

  testWidgets('écran pas prêt : renvoie false pour que l\'appelant réessaie', (
    tester,
  ) async {
    final service = _FakeUpdates(update);

    final handled = await maybeShowAppUpdatePrompt(
      () => null,
      service: service,
      now: t0,
    );

    expect(handled, isFalse);
    expect(service.checks, 1);
  });

  testWidgets('n\'interroge pas le store à chaque retour au premier plan', (
    tester,
  ) async {
    final context = await pumpApp(tester);
    final service = _FakeUpdates(null);

    await maybeShowAppUpdatePrompt(() => context, service: service, now: t0);
    await maybeShowAppUpdatePrompt(
      () => context,
      service: service,
      now: t0.add(const Duration(minutes: 10)),
    );
    expect(service.checks, 1);

    await maybeShowAppUpdatePrompt(
      () => context,
      service: service,
      now: t0.add(const Duration(hours: 2)),
    );
    expect(service.checks, 2);
  });

  testWidgets('aucune boîte quand le store n\'a pas de version plus récente', (
    tester,
  ) async {
    final context = await pumpApp(tester);

    final handled = await maybeShowAppUpdatePrompt(
      () => context,
      service: _FakeUpdates(null),
      now: t0,
    );
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('Mise à jour disponible'), findsNothing);
  });
}
