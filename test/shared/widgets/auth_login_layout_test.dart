import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/shared/widgets/auth_login_layout.dart';

void main() {
  group('AuthLoginLayout', () {
    testWidgets('does not render the demo login option', (tester) async {
      await _pumpAuthLoginLayout(tester);

      expect(find.text('Continuer sans connexion (d\u00e9mo)'), findsNothing);
    });

    testWidgets('toggles password visibility from the suffix icon', (
      tester,
    ) async {
      await _pumpAuthLoginLayout(tester);

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(_passwordField(tester).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(_passwordField(tester).obscureText, isFalse);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(_passwordField(tester).obscureText, isTrue);
    });

    testWidgets('accepts a 4-digit password at login', (tester) async {
      var loginCalls = 0;
      await _pumpAuthLoginLayout(tester, onLogin: () => loginCalls++);

      final fields = find.byType(EditableText);
      await tester.enterText(fields.first, '0565855202');
      await tester.enterText(fields.last, '1234');
      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      expect(find.text('Mot de passe trop court'), findsNothing);
      expect(loginCalls, 1);
    });

    testWidgets('clears the too-short error once 4 digits are typed', (
      tester,
    ) async {
      await _pumpAuthLoginLayout(tester);

      final fields = find.byType(EditableText);
      await tester.enterText(fields.first, '0565855202');
      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      await tester.enterText(fields.last, '1');
      await tester.pump();
      expect(find.text('Mot de passe trop court'), findsOneWidget);

      await tester.enterText(fields.last, '1234');
      await tester.pump();
      expect(find.text('Mot de passe trop court'), findsNothing);
    });

    testWidgets('refuses a password shorter than 4 characters at login', (
      tester,
    ) async {
      var loginCalls = 0;
      await _pumpAuthLoginLayout(tester, onLogin: () => loginCalls++);

      final fields = find.byType(EditableText);
      await tester.enterText(fields.first, '0565855202');
      await tester.enterText(fields.last, '123');
      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      expect(find.text('Mot de passe trop court'), findsOneWidget);
      expect(loginCalls, 0);
    });

    testWidgets('keeps the login action wired after the password toggle', (
      tester,
    ) async {
      var loginCalls = 0;

      await _pumpAuthLoginLayout(
        tester,
        onLogin: () {
          loginCalls++;
        },
      );

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      expect(loginCalls, 1);
    });
  });
}

Future<void> _pumpAuthLoginLayout(
  WidgetTester tester, {
  VoidCallback? onLogin,
}) async {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  addTearDown(phoneController.dispose);
  addTearDown(passwordController.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: AuthLoginLayout(
        subtitle: 'Connectez-vous pour continuer',
        isPassenger: true,
        phoneController: phoneController,
        passwordController: passwordController,
        onLogin: onLogin ?? () {},
        isLoading: false,
        formKey: GlobalKey<FormState>(),
        onSignup: () {},
      ),
    ),
  );
}

EditableText _passwordField(WidgetTester tester) {
  return tester.widgetList<EditableText>(find.byType(EditableText)).last;
}
