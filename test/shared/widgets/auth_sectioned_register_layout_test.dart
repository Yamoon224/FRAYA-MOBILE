import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/auth_register_draft.dart';
import 'package:fraya_mobile/shared/widgets/auth_sectioned_register_layout.dart';

void main() {
  group('AuthSectionedRegisterLayout', () {
    testWidgets('shows phone and optional email in contact step', (
      tester,
    ) async {
      await _pumpLayout(tester, step: AuthRegisterFlowStep.contact);

      expect(find.text('Numero de telephone'), findsOneWidget);
      expect(find.text('Email (optionnel)'), findsOneWidget);
      expect(find.text('Recevoir le code'), findsOneWidget);
    });

    testWidgets('disables OTP resend while countdown is active', (
      tester,
    ) async {
      await _pumpLayout(
        tester,
        step: AuthRegisterFlowStep.otp,
        otpResendSecondsRemaining: 30,
      );

      expect(find.text('Renvoyer dans 30s'), findsOneWidget);

      final button = tester.widget<GestureDetector>(
        find
            .ancestor(
              of: find.text('Renvoyer dans 30s'),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      expect(button.onTapUp, isNull);
    });
  });
}

Future<void> _pumpLayout(
  WidgetTester tester, {
  required AuthRegisterFlowStep step,
  int otpResendSecondsRemaining = 0,
}) async {
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final firstNamesController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  addTearDown(phoneController.dispose);
  addTearDown(emailController.dispose);
  addTearDown(otpController.dispose);
  addTearDown(firstNamesController.dispose);
  addTearDown(lastNameController.dispose);
  addTearDown(passwordController.dispose);
  addTearDown(confirmPasswordController.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: AuthSectionedRegisterLayout(
        subtitle: 'Creation de compte',
        currentStep: step,
        phoneController: phoneController,
        emailController: emailController,
        otpController: otpController,
        firstNamesController: firstNamesController,
        lastNameController: lastNameController,
        passwordController: passwordController,
        confirmPasswordController: confirmPasswordController,
        selectedGenre: null,
        onGenreChanged: (_) {},
        onSendOtp: () async {},
        onVerifyOtp: () async {},
        onResendOtp: () async {},
        onCompleteRegistration: () async {},
        onBack: () {},
        onLogin: () {},
        isLoading: false,
        isResendingOtp: false,
        otpResendSecondsRemaining: otpResendSecondsRemaining,
      ),
    ),
  );
}
