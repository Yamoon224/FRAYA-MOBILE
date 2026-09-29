import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/responsive.dart';
import '../providers/forgot_password_provider.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/auth_otp_dialog.dart';
import '../widgets/auth_password_rules.dart';
import '../widgets/fraya_button.dart';
import '../widgets/fraya_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  static final _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
  );

  bool _isPasswordObscured = true;
  bool _isConfirmObscured = true;
  bool _isOtpDialogOpen = false;
  int _step = 1;
  String? _verificationCode;
  String _newPassword = '';

  bool get _canSubmitReset =>
      _verificationCode != null &&
      _passwordRegex.hasMatch(_newPasswordController.text) &&
      _confirmPasswordController.text == _newPasswordController.text;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_refreshSubmitState);
    _confirmPasswordController.addListener(_refreshSubmitState);
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_refreshSubmitState);
    _confirmPasswordController.removeListener(_refreshSubmitState);
    _identifierController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _refreshSubmitState() {
    if (!mounted) return;
    setState(() => _newPassword = _newPasswordController.text);
  }

  void _onSubmitStep1() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(forgotPasswordProvider.notifier)
        .sendResetCode(_identifierController.text.trim());
  }

  void _onSubmitStep2() {
    if (!_canSubmitReset) return;
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(forgotPasswordProvider.notifier)
        .resetPassword(_verificationCode!, _newPasswordController.text);
  }

  Future<void> _showOtpDialog() async {
    if (_isOtpDialogOpen) return;
    _isOtpDialogOpen = true;
    final result = await showAuthOtpDialog(
      context: context,
      title: 'Vérification SMS',
      description: 'Entrez le code reçu par SMS ou e-mail.',
      onSubmit: (otp) async {
        _verificationCode = otp;
      },
      onResend: () async {
        await ref
            .read(forgotPasswordProvider.notifier)
            .sendResetCode(_identifierController.text.trim());
        final state = ref.read(forgotPasswordProvider);
        if (state.status == ForgotPasswordStatus.error &&
            state.errorMessage != null) {
          throw Exception(state.errorMessage);
        }
      },
    );
    _isOtpDialogOpen = false;
    if (result == true && mounted) {
      setState(() => _step = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ForgotPasswordState>(forgotPasswordProvider, (_, next) {
      if (next.status == ForgotPasswordStatus.codeSent && !_isOtpDialogOpen) {
        _showOtpDialog();
      }
      if (next.status == ForgotPasswordStatus.success) {
        AppSnackBar.showSuccess(
          context,
          'Mot de passe réinitialisé avec succès !',
        );
        context.go('/login');
      }
      if (next.status == ForgotPasswordStatus.error &&
          next.errorMessage != null &&
          !_isOtpDialogOpen) {
        AppSnackBar.showError(context, next.errorMessage!);
      }
    });

    final isLoading =
        ref.watch(forgotPasswordProvider).status ==
        ForgotPasswordStatus.loading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6);
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final hPad = context.responsiveValue<double>(
      compact: AppTheme.spacingLg,
      phone: 24,
      largePhone: 28,
      tablet: 40,
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        foregroundColor: titleColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 2) {
              setState(() => _step = 1);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          'Mot de passe oublié',
          style: AppTextStyles.h3.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepIndicator(currentStep: _step, isDark: isDark),
                const SizedBox(height: 28),
                _StepHeader(step: _step, isDark: isDark),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _step == 1
                      ? _Step1Content(
                          key: const ValueKey(1),
                          controller: _identifierController,
                          isDark: isDark,
                          surfaceColor: surfaceColor,
                        )
                      : _Step2Content(
                          key: const ValueKey(2),
                          newPasswordController: _newPasswordController,
                          confirmPasswordController: _confirmPasswordController,
                          isPasswordObscured: _isPasswordObscured,
                          isConfirmObscured: _isConfirmObscured,
                          isDark: isDark,
                          surfaceColor: surfaceColor,
                          newPassword: _newPassword,
                          onTogglePassword: () => setState(
                            () => _isPasswordObscured = !_isPasswordObscured,
                          ),
                          onToggleConfirm: () => setState(
                            () => _isConfirmObscured = !_isConfirmObscured,
                          ),
                          onPasswordChanged: (v) =>
                              setState(() => _newPassword = v),
                        ),
                ),
                const SizedBox(height: 28),
                FrayaButton(
                  label: _step == 1
                      ? 'Recevoir le code'
                      : 'Réinitialiser le mot de passe',
                  onPressed: isLoading
                      ? null
                      : _step == 1
                      ? _onSubmitStep1
                      : _canSubmitReset
                      ? _onSubmitStep2
                      : null,
                  isLoading: isLoading,
                  size: FrayaButtonSize.lg,
                  leftIcon: _step == 1
                      ? Icons.send_rounded
                      : Icons.check_rounded,
                ),
                if (_step == 2) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _step = 1),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Retour à l\'étape précédente'),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.isDark});

  final int currentStep;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final connectorColor = currentStep >= 2
        ? AppColors.primaryDark
        : (isDark ? AppColors.darkBorder : AppColors.greyLight);
    final labelColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Column(
      children: [
        Row(
          children: [
            _StepCircle(
              number: 1,
              isActive: currentStep == 1,
              isDone: currentStep > 1,
            ),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                decoration: BoxDecoration(
                  gradient: currentStep >= 2 ? AppColors.goldGradient : null,
                  color: currentStep >= 2 ? null : connectorColor,
                ),
              ),
            ),
            _StepCircle(number: 2, isActive: currentStep == 2, isDone: false),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Envoi du code',
                style: AppTextStyles.xs.copyWith(
                  color: currentStep == 1 ? AppColors.primaryDark : labelColor,
                  fontWeight: currentStep == 1
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Nouveau mot de passe',
                textAlign: TextAlign.end,
                style: AppTextStyles.xs.copyWith(
                  color: currentStep == 2 ? AppColors.primaryDark : labelColor,
                  fontWeight: currentStep == 2
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.number,
    required this.isActive,
    required this.isDone,
  });

  final int number;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = isActive || isDone;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: isHighlighted ? AppColors.goldGradient : null,
        color: isHighlighted
            ? null
            : Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurfaceElevated
            : AppColors.greyLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isDone
            ? const Icon(
                Icons.check_rounded,
                size: 16,
                color: AppColors.textPrimary,
              )
            : Text(
                '$number',
                style: AppTextStyles.small.copyWith(
                  color: isActive
                      ? AppColors.textPrimary
                      : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextTertiary
                            : AppColors.textSecondary),
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ── Step headers ──────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.isDark});

  final int step;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isStep1 = step == 1;
    final title = isStep1 ? 'Récupération du compte' : 'Nouveau mot de passe';
    final subtitle = isStep1
        ? 'Entrez votre numéro de téléphone ou adresse e-mail pour recevoir un code de réinitialisation.'
        : 'Choisissez un mot de passe fort et unique pour sécuriser votre compte.';
    final icon = isStep1
        ? Icons.phone_android_rounded
        : Icons.lock_reset_rounded;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            gradient: AppColors.goldGradient,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: AppTextStyles.small.copyWith(
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step 1 content ────────────────────────────────────────────────────────────

class _Step1Content extends StatelessWidget {
  const _Step1Content({
    super.key,
    required this.controller,
    required this.isDark,
    required this.surfaceColor,
  });

  final TextEditingController controller;
  final bool isDark;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    final infoTextColor = isDark
        ? const Color(0xFF93C5FD)
        : const Color(0xFF1D4ED8);
    final infoBgColor = isDark
        ? AppColors.darkInfoBackground
        : const Color(0xFFEFF6FF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FrayaTextField(
          controller: controller,
          label: 'Téléphone ou e-mail',
          hint: '07 12 34 56 78 ou exemple@email.com',
          prefixIcon: Icons.person_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer votre téléphone ou e-mail';
            }
            final v = value.trim();
            final isPhone = RegExp(r'^\d{10}$').hasMatch(v);
            final isEmail = v.isValidEmail;
            if (!isPhone && !isEmail) {
              return 'Numéro (10 chiffres) ou e-mail invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: infoBgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: infoTextColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Un code à 6 chiffres vous sera envoyé par SMS ou e-mail pour vérifier votre identité.',
                  style: AppTextStyles.xs.copyWith(
                    color: infoTextColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step 2 content ────────────────────────────────────────────────────────────

class _Step2Content extends StatelessWidget {
  const _Step2Content({
    super.key,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.isPasswordObscured,
    required this.isConfirmObscured,
    required this.isDark,
    required this.surfaceColor,
    required this.newPassword,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onPasswordChanged,
  });

  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool isPasswordObscured;
  final bool isConfirmObscured;
  final bool isDark;
  final Color surfaceColor;
  final String newPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final ValueChanged<String> onPasswordChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FrayaTextField(
                  controller: newPasswordController,
                  label: 'Nouveau mot de passe',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  obscureText: isPasswordObscured,
                  suffixIcon: isPasswordObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onSuffixTap: onTogglePassword,
                  onChanged: onPasswordChanged,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (!_ForgotPasswordScreenState._passwordRegex.hasMatch(
                      value,
                    )) {
                      return 'Min. 8 caractères, une majuscule, une minuscule et un chiffre';
                    }
                    return null;
                  },
                ),
                PasswordRules(password: newPassword),
                const SizedBox(height: 14),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: FrayaTextField(
              controller: confirmPasswordController,
              label: 'Confirmer le mot de passe',
              hint: '••••••••',
              prefixIcon: Icons.check_circle_outline_rounded,
              obscureText: isConfirmObscured,
              suffixIcon: isConfirmObscured
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              onSuffixTap: onToggleConfirm,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez confirmer votre mot de passe';
                }
                if (value != newPasswordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
