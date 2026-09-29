import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import 'auth_password_rules.dart';
import 'fraya_button.dart';
import 'fraya_text_field.dart';
import 'legal_document_dialog.dart';
import 'settings/legal_content.dart';

class AuthRegisterLayout extends StatefulWidget {
  const AuthRegisterLayout({
    super.key,
    required this.subtitle,
    required this.isDriver,
    required this.firstNamesController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.selectedGenre,
    required this.onGenreChanged,
    required this.onRegister,
    required this.isLoading,
    required this.formKey,
    this.onLogin,
  });

  final String subtitle;
  final bool isDriver;
  final TextEditingController firstNamesController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? selectedGenre;
  final ValueChanged<String?> onGenreChanged;
  final VoidCallback onRegister;
  final bool isLoading;
  final GlobalKey<FormState> formKey;
  final VoidCallback? onLogin;

  @override
  State<AuthRegisterLayout> createState() => _AuthRegisterLayoutState();
}

class _AuthRegisterLayoutState extends State<AuthRegisterLayout> {
  static final Uri _cguUri = Uri.parse(
    'https://manager.frayataxi.ci/legal/cgu-fraya-taxi.pdf',
  );
  static final Uri _cgvUri = Uri.parse(
    'https://manager.frayataxi.ci/legal/cgv-fraya-taxi-sa.pdf',
  );

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _termsAccepted = false;

  List<TextEditingController> get _requiredSubmitControllers => [
    widget.firstNamesController,
    widget.lastNameController,
    widget.passwordController,
  ];

  static final _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
  );

  bool get _canSubmit =>
      _termsAccepted &&
      !widget.isLoading &&
      widget.firstNamesController.text.trim().isNotEmpty &&
      widget.lastNameController.text.trim().isNotEmpty &&
      _passwordRegex.hasMatch(widget.passwordController.text);

  @override
  void initState() {
    super.initState();
    for (final controller in _requiredSubmitControllers) {
      controller.addListener(_refreshSubmitState);
    }
  }

  @override
  void didUpdateWidget(covariant AuthRegisterLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldControllers = [
      oldWidget.firstNamesController,
      oldWidget.lastNameController,
      oldWidget.passwordController,
    ];
    final newControllers = _requiredSubmitControllers;

    for (var i = 0; i < newControllers.length; i++) {
      if (oldControllers[i] == newControllers[i]) continue;
      oldControllers[i].removeListener(_refreshSubmitState);
      newControllers[i].addListener(_refreshSubmitState);
    }
  }

  @override
  void dispose() {
    for (final controller in _requiredSubmitControllers) {
      controller.removeListener(_refreshSubmitState);
    }
    super.dispose();
  }

  void _refreshSubmitState() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Form(
            key: widget.formKey,
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
                const SizedBox(height: 40),
                Text(
                  'Inscription',
                  style: AppTextStyles.h1.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  widget.subtitle,
                  style: AppTextStyles.body.copyWith(color: secondaryTextColor),
                ),
                const SizedBox(height: 32),
                FrayaTextField(
                  controller: widget.firstNamesController,
                  label: 'Pr\u00e9noms',
                  hint: 'Ex: Jean Marc',
                  prefixIcon: Icons.person_outline,
                  isRequired: true,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Champ requis'
                      : null,
                ),
                const SizedBox(height: 16),
                FrayaTextField(
                  controller: widget.lastNameController,
                  label: 'Nom',
                  hint: 'Ex: Kouassi',
                  prefixIcon: Icons.person_outline,
                  isRequired: true,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Champ requis'
                      : null,
                ),
                const SizedBox(height: 16),
                FrayaTextField(
                  controller: widget.emailController,
                  label: 'Email (optionnel)',
                  hint: 'jean.marc@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FrayaTextField(
                  controller: widget.phoneController,
                  label: 'Num\u00e9ro de t\u00e9l\u00e9phone',
                  hint: '07 12 34 56 78',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  isRequired: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) => value == null || value.length < 10
                      ? 'Num\u00e9ro invalide'
                      : null,
                ),
                const SizedBox(height: 16),
                FrayaTextField(
                  controller: widget.passwordController,
                  label: 'Mot de passe',
                  hint: '********',
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: _isPasswordObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  isRequired: true,
                  onSuffixTap: () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  },
                  obscureText: _isPasswordObscured,
                  validator: _validatePassword,
                ),
                PasswordRules(password: widget.passwordController.text),
                const SizedBox(height: 16),
                FrayaTextField(
                  controller: widget.confirmPasswordController,
                  label: 'Confirmer le mot de passe',
                  hint: '********',
                  prefixIcon: Icons.lock_clock_outlined,
                  suffixIcon: _isConfirmPasswordObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  isRequired: true,
                  onSuffixTap: () {
                    setState(() {
                      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                    });
                  },
                  obscureText: _isConfirmPasswordObscured,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }
                    if (value != widget.passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Genre', style: AppTextStyles.h4),
                const SizedBox(height: AppTheme.spacingSm),
                DropdownButtonFormField<String>(
                  initialValue: widget.selectedGenre,
                  items: ['MASCULIN', 'FEMININ', 'AUTRES']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: widget.onGenreChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.wc, color: AppColors.grey),
                    hintText: 'S\u00e9lectionnez votre genre',
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (value) =>
                          setState(() => _termsAccepted = value ?? false),
                      activeColor: AppColors.primaryDark,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => setState(
                                () => _termsAccepted = !_termsAccepted,
                              ),
                              child: Text(
                                "J'accepte les Conditions Générales d'Utilisation (CGU), les Conditions Générales de Vente (CGV) et la Politique de confidentialité de Fraya Taxi.",
                                style: AppTextStyles.small,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                _legalLink(
                                  'Voir les CGU',
                                  () => _showLegalPdf(
                                    title: "Conditions Générales d'Utilisation",
                                    uri: _cguUri,
                                  ),
                                ),
                                _legalLink(
                                  'Voir les CGV',
                                  () => _showLegalPdf(
                                    title: 'Conditions Générales de Vente',
                                    uri: _cgvUri,
                                  ),
                                ),
                                _legalLink(
                                  'Politique de confidentialité',
                                  _showPrivacyPolicy,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FrayaButton(
                  label: "S'inscrire",
                  onPressed: _canSubmit ? widget.onRegister : null,
                  isLoading: widget.isLoading,
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: widget.onLogin,
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.small.copyWith(
                          color: secondaryTextColor,
                        ),
                        children: [
                          const TextSpan(text: 'D\u00e9j\u00e0 un compte ? '),
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
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legalLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          label,
          style: AppTextStyles.small.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }

  Future<void> _showLegalPdf({required String title, required Uri uri}) {
    return showLegalPdfDialog(context, title: title, uri: uri);
  }

  Future<void> _showPrivacyPolicy() {
    return showLegalTextDialog(
      context,
      title: 'Politique de confidentialité',
      sections: LegalContent.privacyPolicy(),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Champ requis';
    if (!_passwordRegex.hasMatch(value)) {
      return 'Min. 8 caract\u00e8res, une majuscule, une minuscule et un chiffre';
    }
    return null;
  }
}
