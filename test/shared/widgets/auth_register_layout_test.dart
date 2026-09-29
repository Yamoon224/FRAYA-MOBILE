import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/shared/widgets/auth_register_layout.dart';

void main() {
  group('AuthRegisterLayout', () {
    testWidgets('toggles the main password field visibility independently', (
      tester,
    ) async {
      await _pumpAuthRegisterLayout(tester);

      expect(_editableFields(tester).elementAt(4).obscureText, isTrue);
      expect(_editableFields(tester).elementAt(5).obscureText, isTrue);

      await tester.ensureVisible(
        find.byIcon(Icons.visibility_off_outlined).first,
      );
      await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
      await tester.pump();

      expect(_editableFields(tester).elementAt(4).obscureText, isFalse);
      expect(_editableFields(tester).elementAt(5).obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('toggles the confirm password field visibility independently', (
      tester,
    ) async {
      await _pumpAuthRegisterLayout(tester);

      await tester.ensureVisible(
        find.byIcon(Icons.visibility_off_outlined).last,
      );
      await tester.tap(find.byIcon(Icons.visibility_off_outlined).last);
      await tester.pump();

      expect(_editableFields(tester).elementAt(4).obscureText, isTrue);
      expect(_editableFields(tester).elementAt(5).obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('keeps the register action wired after toggling visibility', (
      tester,
    ) async {
      var registerCalls = 0;

      await _pumpAuthRegisterLayout(
        tester,
        onRegister: () {
          registerCalls++;
        },
      );

      await tester.ensureVisible(
        find.byIcon(Icons.visibility_off_outlined).first,
      );
      await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
      await tester.pump();
      await tester.ensureVisible(find.text("S'inscrire"));
      await tester.tap(find.text("S'inscrire"));
      await tester.pump();

      expect(registerCalls, 1);
    });
  });
}

Future<void> _pumpAuthRegisterLayout(
  WidgetTester tester, {
  VoidCallback? onRegister,
}) async {
  final firstNamesController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  addTearDown(firstNamesController.dispose);
  addTearDown(lastNameController.dispose);
  addTearDown(emailController.dispose);
  addTearDown(phoneController.dispose);
  addTearDown(passwordController.dispose);
  addTearDown(confirmPasswordController.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: AuthRegisterLayout(
        subtitle: 'Cr\u00e9ez votre compte',
        isDriver: false,
        firstNamesController: firstNamesController,
        lastNameController: lastNameController,
        emailController: emailController,
        phoneController: phoneController,
        passwordController: passwordController,
        confirmPasswordController: confirmPasswordController,
        selectedGenre: 'MASCULIN',
        onGenreChanged: (_) {},
        onRegister: onRegister ?? () {},
        isLoading: false,
        formKey: GlobalKey<FormState>(),
        onLogin: () {},
      ),
    ),
  );
}

Iterable<EditableText> _editableFields(WidgetTester tester) {
  return tester.widgetList<EditableText>(find.byType(EditableText));
}
