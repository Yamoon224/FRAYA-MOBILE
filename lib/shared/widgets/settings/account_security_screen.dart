import 'package:flutter/services.dart';
import '../../../core/utils/password_policy.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
    this.title = 'Sécurité du compte',
  });

  final bool isSubmitting;
  final Future<void> Function(String oldPassword, String newPassword) onSubmit;
  final String title;

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = context.responsiveValue<double>(
      compact: AppTheme.spacingMd,
      phone: AppTheme.spacingLg,
      largePhone: 24,
      tablet: 32,
    );

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.title,
          style: AppTextStyles.h3.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SecurityHeader(),
              const SizedBox(height: 28),
              _FieldsCard(
                children: [
                  _PasswordField(
                    label: 'Mot de passe actuel',
                    hint: 'Entrez votre mot de passe actuel',
                    controller: _oldPasswordController,
                    obscureText: _obscureOld,
                    prefixIcon: Icons.lock_outline_rounded,
                    onToggleVisibility: () =>
                        setState(() => _obscureOld = !_obscureOld),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Champ requis.' : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const _FieldDivider(),
                  _PasswordField(
                    label: 'Nouveau mot de passe',
                    hint: PasswordPolicy.hint,
                    keyboardType: PasswordPolicy.keyboardType,
                    inputFormatters: PasswordPolicy.inputFormatters,
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    prefixIcon: Icons.lock_reset_rounded,
                    onToggleVisibility: () =>
                        setState(() => _obscureNew = !_obscureNew),
                    validator: (v) {
                      if (!PasswordPolicy.isValidNew(v)) {
                        return '${PasswordPolicy.invalidMessage}.';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const _FieldDivider(),
                  _PasswordField(
                    label: 'Confirmer le nouveau mot de passe',
                    hint: 'Répétez les 4 chiffres',
                    keyboardType: PasswordPolicy.keyboardType,
                    inputFormatters: PasswordPolicy.inputFormatters,
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    prefixIcon: Icons.check_circle_outline_rounded,
                    onToggleVisibility: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return 'Champ requis.';
                      if (v!.trim() != _newPasswordController.text.trim()) {
                        return 'Les mots de passe ne correspondent pas.';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _PasswordTip(),
              const SizedBox(height: 28),
              _SubmitButton(
                isSubmitting: widget.isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(
      _oldPasswordController.text.trim(),
      _newPasswordController.text.trim(),
    );
  }
}

// ─── Security header ──────────────────────────────────────────────────────────

class _SecurityHeader extends StatelessWidget {
  const _SecurityHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            gradient: AppColors.goldGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: AppColors.textPrimary,
            size: 26,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modifier le mot de passe',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choisissez un mot de passe fort et unique.',
                style: AppTextStyles.small.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Card container for fields ────────────────────────────────────────────────

class _FieldsCard extends StatelessWidget {
  const _FieldsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: context.colors.border);
  }
}

// ─── Single password field ────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscureText,
    required this.prefixIcon,
    required this.onToggleVisibility,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final IconData prefixIcon;
  final VoidCallback onToggleVisibility;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final iconColor = context.colors.textSecondary;
    const errorColor = AppColors.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            style: AppTextStyles.body.copyWith(
              color: context.colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.body.copyWith(
                color: context.colors.textTertiary,
              ),
              filled: true,
              fillColor: context.colors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(prefixIcon, color: iconColor, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: iconColor,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
                splashRadius: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: context.colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: context.colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(
                  color: context.colors.isDark
                      ? AppColors.primaryLight
                      : AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: const BorderSide(color: errorColor),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: const BorderSide(color: errorColor, width: 1.5),
              ),
              errorStyle: AppTextStyles.xs.copyWith(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Password tips ────────────────────────────────────────────────────────────

class _PasswordTip extends StatelessWidget {
  const _PasswordTip();

  @override
  Widget build(BuildContext context) {
    final bgColor = context.colors.infoBackground;
    final iconColor = context.colors.isDark
        ? const Color(0xFF93C5FD)
        : const Color(0xFF3B82F6);
    final textColor = context.colors.isDark
        ? const Color(0xFF93C5FD)
        : const Color(0xFF1D4ED8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Choisissez un code de 4 chiffres facile à retenir et ne le partagez '
              'avec personne. Évitez les codes évidents comme 1234 ou 0000.',
              style: AppTextStyles.xs.copyWith(color: textColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Submit button ────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: isSubmitting ? null : AppColors.goldGradient,
        color: isSubmitting ? AppColors.greyLight : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: isSubmitting ? null : AppColors.shadowYellowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSubmitting ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Center(
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textPrimary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mettre à jour le mot de passe',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
