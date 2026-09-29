import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'auth_password_rules.dart';
import 'auth_register_section_widgets.dart';
import 'fraya_button.dart';
import 'fraya_text_field.dart';
import 'legal_document_dialog.dart';
import 'settings/legal_content.dart';

class AuthRegisterDetailsStep extends StatefulWidget {
  const AuthRegisterDetailsStep({
    super.key,
    required this.firstNamesController,
    required this.lastNameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.selectedGenre,
    required this.onGenreChanged,
    required this.isLoading,
    required this.onSubmit,
    required this.onBack,
    this.dateOfBirthController,
  });

  final TextEditingController firstNamesController;
  final TextEditingController lastNameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? selectedGenre;
  final ValueChanged<String?> onGenreChanged;
  final bool isLoading;
  final Future<void> Function() onSubmit;
  final VoidCallback onBack;
  final TextEditingController? dateOfBirthController;

  @override
  State<AuthRegisterDetailsStep> createState() =>
      _AuthRegisterDetailsStepState();
}

class _AuthRegisterDetailsStepState extends State<AuthRegisterDetailsStep> {
  static final Uri _cguUri = Uri.parse(
    'https://manager.frayataxi.ci/legal/cgu-fraya-taxi.pdf',
  );
  static final Uri _cgvUri = Uri.parse(
    'https://manager.frayataxi.ci/legal/cgv-fraya-taxi-sa.pdf',
  );

  final _formKey = GlobalKey<FormState>();
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
  void didUpdateWidget(covariant AuthRegisterDetailsStep oldWidget) {
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
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _identitySection(),
          const SizedBox(height: 16),
          _securitySection(),
          const SizedBox(height: 16),
          _genreSection(),
          const SizedBox(height: 24),
          _termsCheckbox(),
          const SizedBox(height: 24),
          FrayaButton(
            label: "Finaliser l'inscription",
            onPressed: _canSubmit ? _submit : null,
            isLoading: widget.isLoading,
          ),
          const SizedBox(height: 12),
          FrayaButton(
            label: 'Retour au code OTP',
            variant: FrayaButtonVariant.ghost,
            onPressed: widget.isLoading ? null : widget.onBack,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    final day = picked.day.toString().padLeft(2, '0');
    final month = picked.month.toString().padLeft(2, '0');
    widget.dateOfBirthController?.text = '$day-$month-${picked.year}';
  }

  Widget _identitySection() {
    return AuthRegisterSectionSurface(
      title: 'Identité',
      children: [
        FrayaTextField(
          controller: widget.firstNamesController,
          label: 'Prenoms',
          hint: 'Ex: Jean Marc',
          prefixIcon: Icons.person_outline,
          isRequired: true,
          validator: requiredRegisterField,
        ),
        const SizedBox(height: 16),
        FrayaTextField(
          controller: widget.lastNameController,
          label: 'Nom',
          hint: 'Ex: Kouassi',
          prefixIcon: Icons.person_outline,
          isRequired: true,
          validator: requiredRegisterField,
        ),
        if (widget.dateOfBirthController != null) ...[
          const SizedBox(height: 16),
          FrayaTextField(
            controller: widget.dateOfBirthController,
            label: 'Date de naissance',
            hint: 'JJ-MM-AAAA',
            prefixIcon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: _pickDate,
            isRequired: true,
            validator: (value) =>
                value == null || value.isEmpty ? 'Champ requis' : null,
          ),
        ],
      ],
    );
  }

  Widget _securitySection() {
    return AuthRegisterSectionSurface(
      title: 'Sécurité',
      children: [
        FrayaTextField(
          controller: widget.passwordController,
          label: 'Mot de passe',
          hint: '********',
          prefixIcon: Icons.lock_outline,
          suffixIcon: _isPasswordObscured
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          isRequired: true,
          onSuffixTap: () =>
              setState(() => _isPasswordObscured = !_isPasswordObscured),
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
          onSuffixTap: () => setState(
            () => _isConfirmPasswordObscured = !_isConfirmPasswordObscured,
          ),
          obscureText: _isConfirmPasswordObscured,
          validator: _validateConfirmPassword,
        ),
      ],
    );
  }

  Widget _genreSection() {
    return AuthRegisterSectionSurface(
      title: 'Genre',
      children: [
        DropdownButtonFormField<String>(
          initialValue: widget.selectedGenre,
          items: [
            'MASCULIN',
            'FEMININ',
            'AUTRE',
          ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: widget.onGenreChanged,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.wc, color: AppColors.grey),
            hintText: 'Sélectionnez votre genre',
          ),
        ),
      ],
    );
  }

  Widget _termsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _termsAccepted,
          onChanged: (value) => setState(() => _termsAccepted = value ?? false),
          activeColor: AppColors.primaryDark,
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _termsAccepted = !_termsAccepted),
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
      return 'Min. 8 caractères, une majuscule, une minuscule et un chiffre';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirmation requise';
    if (value != widget.passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    await widget.onSubmit();
  }
}
