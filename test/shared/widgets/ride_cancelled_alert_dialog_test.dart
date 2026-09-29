import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/shared/widgets/confirmation_action_column.dart';
import 'package:fraya_mobile/shared/widgets/ride_cancelled_alert_dialog.dart';

void main() {
  testWidgets('blocks external dismissal and returns the primary action', (
    tester,
  ) async {
    RideCancelledAlertAction? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showRideCancelledAlertDialog(
                context,
                message: 'La course a ete annulee.',
                actionLabel: 'J\'ai compris',
              );
            },
            child: const Text('Afficher'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Afficher'));
    await tester.pump();

    expect(find.text('Course annulée'), findsOneWidget);
    expect(find.byType(ConfirmationActionColumn), findsOneWidget);
    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    expect(find.text('Course annulée'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Course annulée'), findsOneWidget);

    await tester.tap(find.text('J\'ai compris'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Course annulée'), findsNothing);
    expect(result, RideCancelledAlertAction.primary);
  });

  testWidgets('returns the secondary action below the primary action', (
    tester,
  ) async {
    RideCancelledAlertAction? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showRideCancelledAlertDialog(
                context,
                message: 'La course a ete annulee.',
                actionLabel: 'Rechercher un chauffeur',
                secondaryActionLabel: 'Revenir a l\'accueil',
              );
            },
            child: const Text('Afficher'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Afficher'));
    await tester.pump();

    final primary = find.text('Rechercher un chauffeur');
    final secondary = find.text('Revenir a l\'accueil');
    expect(primary, findsOneWidget);
    expect(secondary, findsOneWidget);
    expect(
      tester.getTopLeft(primary).dy,
      lessThan(tester.getTopLeft(secondary).dy),
    );

    await tester.tap(secondary);
    await tester.pump();
    await tester.pump();

    expect(result, RideCancelledAlertAction.secondary);
  });

  testWidgets('returns timeout automatically after ten seconds', (
    tester,
  ) async {
    RideCancelledAlertAction? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showRideCancelledAlertDialog(
                context,
                message: 'La course a ete annulee.',
                actionLabel: 'Continuer',
              );
            },
            child: const Text('Afficher'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Afficher'));
    await tester.pump();
    expect(find.text('Redirection automatique dans 10 s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    expect(find.text('Redirection automatique dans 1 s'), findsOneWidget);
    expect(result, isNull);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Course annulée'), findsNothing);
    expect(result, RideCancelledAlertAction.timedOut);
  });
}
