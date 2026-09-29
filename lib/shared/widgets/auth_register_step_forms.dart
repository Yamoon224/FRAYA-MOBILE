import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_register_section_widgets.dart';
import 'fraya_button.dart';
import 'fraya_text_field.dart';

class AuthRegisterContactStep extends StatefulWidget {
  const AuthRegisterContactStep({
    super.key,
    required this.phoneController,
    required this.emailController,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController phoneController;
  final TextEditingController emailController;
  final bool isLoading;
  final Future<void> Function() onSubmit;

  @override
  State<AuthRegisterContactStep> createState() =>
      _AuthRegisterContactStepState();
}

class _AuthRegisterContactStepState extends State<AuthRegisterContactStep> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AuthRegisterSectionSurface(
        title: 'Contact',
        subtitle: 'Nous vérifierons ce numéro par OTP.',
        children: [
          FrayaTextField(
            controller: widget.phoneController,
            label: 'Numéro de téléphone',
            hint: '07 12 34 56 78',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            isRequired: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
            ],
            validator: (value) => value == null || value.trim().length < 10
                ? 'Numéro invalide'
                : null,
          ),
          const SizedBox(height: 16),
          FrayaTextField(
            controller: widget.emailController,
            label: 'Email (optionnel)',
            hint: 'jean.marc@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: validateOptionalRegisterEmail,
          ),
          const SizedBox(height: 24),
          FrayaButton(
            label: 'Recevoir le code',
            rightIcon: Icons.arrow_forward_rounded,
            onPressed: widget.isLoading ? null : _submit,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    await widget.onSubmit();
  }
}

class AuthRegisterOtpStep extends StatefulWidget {
  const AuthRegisterOtpStep({
    super.key,
    required this.otpController,
    required this.isLoading,
    required this.isResendingOtp,
    required this.otpResendSecondsRemaining,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
  });

  final TextEditingController otpController;
  final bool isLoading;
  final bool isResendingOtp;
  final int otpResendSecondsRemaining;
  final Future<void> Function() onVerify;
  final Future<void> Function() onResend;
  final VoidCallback onBack;

  @override
  State<AuthRegisterOtpStep> createState() => _AuthRegisterOtpStepState();
}

class _AuthRegisterOtpStepState extends State<AuthRegisterOtpStep> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final canResend =
        widget.otpResendSecondsRemaining <= 0 && !widget.isResendingOtp;
    return Form(
      key: _formKey,
      child: AuthRegisterSectionSurface(
        title: 'Vérification OTP',
        subtitle: 'Saisissez le code a 4 chiffres reçu par SMS.',
        children: [
          FrayaTextField(
            controller: widget.otpController,
            label: 'Code OTP',
            hint: '1234',
            prefixIcon: Icons.sms_outlined,
            keyboardType: TextInputType.number,
            isRequired: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (value) => value == null || value.trim().length != 4
                ? 'Code OTP invalide'
                : null,
          ),
          const SizedBox(height: 16),
          FrayaButton(
            label: 'Vérifier le code',
            onPressed: widget.isLoading ? null : _verify,
            isLoading: widget.isLoading,
          ),
          const SizedBox(height: 12),
          FrayaButton(
            label: canResend
                ? 'Renvoyer le code'
                : 'Renvoyer dans ${widget.otpResendSecondsRemaining}s',
            variant: FrayaButtonVariant.outline,
            leftIcon: Icons.refresh_rounded,
            onPressed: canResend ? widget.onResend : null,
            isLoading: widget.isResendingOtp,
          ),
          const SizedBox(height: 12),
          FrayaButton(
            label: 'Modifier le contact',
            variant: FrayaButtonVariant.ghost,
            onPressed: widget.isLoading ? null : widget.onBack,
          ),
        ],
      ),
    );
  }

  Future<void> _verify() async {
    if (_formKey.currentState?.validate() != true) return;
    await widget.onVerify();
  }
}
