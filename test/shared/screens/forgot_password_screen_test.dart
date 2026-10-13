import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/usecases/auth/forgot_password_usecase.dart';
import 'package:fraya_mobile/domain/usecases/auth/reset_password_usecase.dart';
import 'package:fraya_mobile/shared/providers/forgot_password_provider.dart';
import 'package:fraya_mobile/shared/screens/forgot_password_screen.dart';
import 'package:go_router/go_router.dart';

import '../../support/forgot_password_test_doubles.dart';

Future<void> _pumpScreen(
  WidgetTester tester,
  RecordingForgotPasswordRepository repository,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/forgot',
    routes: [
      GoRoute(
        path: '/forgot',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('LOGIN_PAGE')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        forgotPasswordProvider.overrideWith(
          (ref) => ForgotPasswordNotifier(
            forgotPasswordUsecase: ForgotPasswordUsecase(repository),
            resetPasswordUsecase: ResetPasswordUsecase(repository),
          ),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _otpField() => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(TextFormField),
);

Future<void> _goToStep2(
  WidgetTester tester, {
  required String typedIdentifier,
  String otp = '1234',
}) async {
  await tester.enterText(find.byType(TextFormField).first, typedIdentifier);
  await tester.tap(find.text('Recevoir le code'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  expect(find.byType(AlertDialog), findsOneWidget);
  await tester.enterText(_otpField(), otp);
  await tester.tap(find.text('Valider'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  expect(find.byType(AlertDialog), findsNothing);
  expect(find.text('Confirmer le mot de passe'), findsOneWidget);
}

Future<void> _submitNewPassword(WidgetTester tester, String password) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), password);
  await tester.enterText(fields.at(1), password);
  await tester.pump();
  await tester.tap(find.text('Réinitialiser le mot de passe'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets(
    'reset sends the phone number typed in step 1 along with the code',
    (tester) async {
      final repository = RecordingForgotPasswordRepository();
      await _pumpScreen(tester, repository);

      await _goToStep2(tester, typedIdentifier: ' 0700000000 ');
      expect(repository.sentIdentifiers, ['0700000000']);

      await _submitNewPassword(tester, 'Secret123');

      expect(repository.resetCalls, hasLength(1));
      final call = repository.resetCalls.single;
      expect(call.verificationCode, '1234');
      expect(call.newPassword, 'Secret123');
      expect(call.identifier, '0700000000');

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('LOGIN_PAGE'), findsOneWidget);
      // Laisse expirer le snackbar de succès (3 s).
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets('reset sends the email typed in step 1', (tester) async {
    final repository = RecordingForgotPasswordRepository(
      resetError: const ServerException(message: 'Code invalide'),
    );
    await _pumpScreen(tester, repository);

    await _goToStep2(tester, typedIdentifier: 'awa@fraya.ci', otp: '6543');
    await _submitNewPassword(tester, 'Secret123');

    final call = repository.resetCalls.single;
    expect(call.identifier, 'awa@fraya.ci');
    expect(call.verificationCode, '6543');
    // Échec serveur : on reste sur l'écran.
    expect(find.text('LOGIN_PAGE'), findsNothing);
    expect(find.text('Code invalide'), findsOneWidget);

    await tester.pump(const Duration(seconds: 11));
  });
}
