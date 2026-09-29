import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'fraya_button.dart';
import 'fraya_text_field.dart';

class AuthLoginLayout extends StatefulWidget {
  const AuthLoginLayout({
    super.key,
    required this.subtitle,
    required this.isPassenger,
    required this.phoneController,
    required this.passwordController,
    required this.onLogin,
    required this.isLoading,
    required this.formKey,
    this.onSignup,
    this.onForgotPassword,
  });

  final String subtitle;
  final bool isPassenger;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final bool isLoading;
  final GlobalKey<FormState> formKey;
  final VoidCallback? onSignup;
  final VoidCallback? onForgotPassword;

  @override
  State<AuthLoginLayout> createState() => _AuthLoginLayoutState();
}

class _AuthLoginLayoutState extends State<AuthLoginLayout> {
  bool _isPasswordObscured = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (widget.isLoading) return;
    final formState = widget.formKey.currentState;
    if (formState == null) return;

    if (!formState.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    FocusScope.of(context).unfocus();
    TextInput.finishAutofillContext();
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final tertiaryTextColor = isDark
        ? AppColors.darkTextTertiary
        : AppColors.textTertiary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.horizontalPagePadding,
          ),
          child: Form(
            key: widget.formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.spacingMd),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/images/logo_fraya.png',
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image_not_supported,
                        color: Colors.red,
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: context.isLandscape
                      ? context.responsiveValue<double>(
                          compact: 40,
                          phone: 52,
                          largePhone: 60,
                          tablet: 70,
                        )
                      : context.responsiveValue<double>(
                          compact: 72,
                          phone: 96,
                          largePhone: 115,
                          tablet: 130,
                        ),
                ),
                Text(
                  'Bienvenue !',
                  style: AppTextStyles.h1.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  widget.subtitle,
                  style: AppTextStyles.body.copyWith(color: secondaryTextColor),
                ),
                const SizedBox(height: 40),
                AutofillGroup(
                  child: Column(
                    children: [
                      FrayaTextField(
                        controller: widget.phoneController,
                        focusNode: _phoneFocusNode,
                        label: 'Numéro de téléphone',
                        hint: '07 12 34 56 78',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                        validator: (value) {
                          final phone = value?.trim() ?? '';
                          if (phone.isEmpty) {
                            return 'Veuillez entrer votre numéro';
                          }
                          if (phone.length < 10) {
                            return 'Numéro invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      FrayaTextField(
                        controller: widget.passwordController,
                        focusNode: _passwordFocusNode,
                        label: 'Mot de passe',
                        hint: '********',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: _isPasswordObscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        onSuffixTap: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                        obscureText: _isPasswordObscured,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        enableSuggestions: false,
                        autocorrect: false,
                        onSubmitted: (_) => _submitLogin(),
                        validator: (value) {
                          final password = value ?? '';
                          if (password.isEmpty) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          if (password.length < 8) {
                            return 'Mot de passe trop court';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: widget.onForgotPassword,
                    child: Text(
                      'Mot de passe oublié ?',
                      style: AppTextStyles.small.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                FrayaButton(
                  label: 'Se connecter',
                  onPressed: widget.isLoading ? null : _submitLogin,
                  isLoading: widget.isLoading,
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OU',
                        style: AppTextStyles.small.copyWith(
                          color: tertiaryTextColor,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 35),
                Center(
                  child: GestureDetector(
                    onTap: widget.onSignup,
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.body.copyWith(
                          color: secondaryTextColor,
                        ),
                        children: [
                          const TextSpan(text: 'Pas encore de compte ? '),
                          TextSpan(
                            text: "S'inscrire",
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: context.isLandscape
                      ? context.responsiveValue<double>(
                          compact: 24,
                          phone: 28,
                          largePhone: 36,
                          tablet: 44,
                        )
                      : context.responsiveValue<double>(
                          compact: 52,
                          phone: 64,
                          largePhone: 80,
                          tablet: 100,
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
