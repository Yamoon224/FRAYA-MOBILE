import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/shared/widgets/auth_otp_dialog.dart';

void main() {
  group('AuthOtpDialog', () {
    testWidgets('shows primary action above cancel action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAuthOtpDialog(
                    context: context,
                    title: 'OTP',
                    description: 'Saisissez le code.',
                    onSubmit: (_) async {},
                  ),
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('Valider')).dy,
        lessThan(tester.getTopLeft(find.text('Annuler')).dy),
      );
      expect(find.text("Renvoyer l'OTP"), findsNothing);
    });

    testWidgets('shows inline validation for empty otp', (tester) async {
      var submitCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAuthOtpDialog(
                    context: context,
                    title: 'OTP',
                    description: 'Saisissez le code.',
                    onSubmit: (_) async {
                      submitCalls++;
                    },
                  ),
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();

      expect(find.text('Veuillez saisir le code OTP.'), findsOneWidget);
      expect(submitCalls, 0);
      expect(find.text('OTP'), findsOneWidget);
    });

    testWidgets('keeps dialog open on error and retries successfully', (
      tester,
    ) async {
      var submitCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAuthOtpDialog(
                    context: context,
                    title: 'OTP',
                    description: 'Saisissez le code.',
                    onSubmit: (otp) async {
                      submitCalls++;
                      if (otp != '1234') {
                        throw Exception('Code OTP invalide');
                      }
                    },
                  ),
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '0000');
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();

      expect(find.text('Code OTP invalide'), findsOneWidget);
      expect(find.text('OTP'), findsOneWidget);
      expect(submitCalls, 1);

      await tester.enterText(find.byType(TextFormField), '1234');
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();

      expect(find.text('OTP'), findsNothing);
      expect(submitCalls, 2);
    });

    testWidgets('returns false when user cancels', (tester) async {
      var result = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result =
                        await showAuthOtpDialog(
                          context: context,
                          title: 'OTP',
                          description: 'Saisissez le code.',
                          onSubmit: (_) async {},
                        ) ??
                        true;
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('disables resend during cooldown', (tester) async {
      await _pumpDialog(tester, onResend: () async {});

      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(find.text('Renvoyer dans 30s'), findsOneWidget);

      final resendButton = tester.widget<GestureDetector>(
        find
            .ancestor(
              of: find.text('Renvoyer dans 30s'),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      expect(resendButton.onTapUp, isNull);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
    });

    testWidgets('resends otp after cooldown and restarts timer', (
      tester,
    ) async {
      var resendCalls = 0;
      await _pumpDialog(
        tester,
        onResend: () async {
          resendCalls++;
        },
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));

      expect(find.text("Renvoyer l'OTP"), findsOneWidget);

      await tester.tap(find.text("Renvoyer l'OTP"));
      await tester.pump();

      expect(resendCalls, 1);
      expect(find.text('Renvoyer dans 30s'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
    });

    testWidgets('keeps dialog open and shows inline resend error', (
      tester,
    ) async {
      await _pumpDialog(
        tester,
        onResend: () async {
          throw Exception('Impossible de renvoyer le code');
        },
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      await tester.tap(find.text("Renvoyer l'OTP"));
      await tester.pump();

      expect(find.text('Impossible de renvoyer le code'), findsOneWidget);
      expect(find.text('OTP'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
    });
  });
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  Future<void> Function()? onResend,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => showAuthOtpDialog(
                context: context,
                title: 'OTP',
                description: 'Saisissez le code.',
                onSubmit: (_) async {},
                onResend: onResend,
              ),
              child: const Text('Open'),
            ),
          );
        },
      ),
    ),
  );
}
