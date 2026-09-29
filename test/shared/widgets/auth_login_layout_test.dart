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
