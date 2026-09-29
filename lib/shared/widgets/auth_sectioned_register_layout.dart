import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/auth_register_draft.dart';
import 'auth_register_details_step.dart';
import 'auth_register_section_widgets.dart';
import 'auth_register_step_forms.dart';

class AuthSectionedRegisterLayout extends StatelessWidget {
  const AuthSectionedRegisterLayout({
    super.key,
    required this.subtitle,
    required this.currentStep,
    required this.phoneController,
    required this.emailController,
    required this.otpController,
    required this.firstNamesController,
    required this.lastNameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.selectedGenre,
    required this.onGenreChanged,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onResendOtp,
    required this.onCompleteRegistration,
    required this.onBack,
    required this.onLogin,
    required this.isLoading,
    required this.isResendingOtp,
    required this.otpResendSecondsRemaining,
    this.dateOfBirthController,
  });

  final String subtitle;
  final AuthRegisterFlowStep currentStep;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController otpController;
  final TextEditingController firstNamesController;
  final TextEditingController lastNameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? selectedGenre;
  final ValueChanged<String?> onGenreChanged;
  final Future<void> Function() onSendOtp;
  final Future<void> Function() onVerifyOtp;
  final Future<void> Function() onResendOtp;
  final Future<void> Function() onCompleteRegistration;
  final VoidCallback onBack;
  final VoidCallback? onLogin;
  final bool isLoading;
  final bool isResendingOtp;
  final int otpResendSecondsRemaining;
  final TextEditingController? dateOfBirthController;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingMd),
              Image.asset('assets/images/logo_fraya.png', height: 40),
              const SizedBox(height: 40),
              Text(
                'Inscription',
                style: AppTextStyles.h1.copyWith(fontSize: 32),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                subtitle,
                style: AppTextStyles.body.copyWith(color: subtitleColor),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              AuthRegisterStepHeader(step: currentStep),
              const SizedBox(height: AppTheme.spacingLg),
              _currentStep(),
              const SizedBox(height: 24),
              _loginLink(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _currentStep() {
    return switch (currentStep) {
      AuthRegisterFlowStep.contact => AuthRegisterContactStep(
        phoneController: phoneController,
        emailController: emailController,
        isLoading: isLoading,
        onSubmit: onSendOtp,
      ),
      AuthRegisterFlowStep.otp => AuthRegisterOtpStep(
        otpController: otpController,
        isLoading: isLoading,
        isResendingOtp: isResendingOtp,
        otpResendSecondsRemaining: otpResendSecondsRemaining,
        onVerify: onVerifyOtp,
        onResend: onResendOtp,
        onBack: onBack,
      ),
      AuthRegisterFlowStep.details => AuthRegisterDetailsStep(
        firstNamesController: firstNamesController,
        lastNameController: lastNameController,
        passwordController: passwordController,
        confirmPasswordController: confirmPasswordController,
        selectedGenre: selectedGenre,
        onGenreChanged: onGenreChanged,
        isLoading: isLoading,
        onSubmit: onCompleteRegistration,
        onBack: onBack,
        dateOfBirthController: dateOfBirthController,
      ),
    };
  }

  Widget _loginLink() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary;
        return Center(
          child: GestureDetector(
            onTap: onLogin,
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.small.copyWith(color: textColor),
                children: [
                  const TextSpan(text: 'Déjà un compte ? '),
                  TextSpan(
                    text: 'Se connecter',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
