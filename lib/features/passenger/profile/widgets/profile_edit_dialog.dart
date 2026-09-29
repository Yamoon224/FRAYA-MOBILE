import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirmation_action_column.dart';
import '../models/profile_model.dart';
import '../providers/profile_provider.dart';

class ProfileEditDialog extends ConsumerStatefulWidget {
  const ProfileEditDialog({super.key, required this.profile});

  final PassengerProfile profile;

  @override
  ConsumerState<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends ConsumerState<ProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.profile.firstName,
    );
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _emailController = TextEditingController(text: widget.profile.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next.success) {
        ref.read(profileControllerProvider.notifier).clearFeedback();
        Navigator.of(context).pop();
        AppSnackBar.showSuccess(context, 'Profil mis à jour');
      } else if (next.errorMessage != null) {
        ref.read(profileControllerProvider.notifier).clearFeedback();
        AppSnackBar.showError(context, next.errorMessage!);
      }
    });

    final isSubmitting = ref.watch(
      profileControllerProvider.select((s) => s.isSubmitting),
    );

    return AlertDialog(
      title: const Text('Modifier le profil'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildField(
                    controller: _firstNameController,
                    label: 'Prénom(s)',
                    icon: Icons.person_outline,
                    enabled: !isSubmitting,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _lastNameController,
                    label: 'Nom',
                    icon: Icons.badge_outlined,
                    enabled: !isSubmitting,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ConfirmationActionColumn(
              primaryLabel: 'Enregistrer',
              onPrimaryPressed: _submit,
              secondaryLabel: 'Annuler',
              onSecondaryPressed: () => Navigator.of(context).pop(),
              isSubmitting: isSubmitting,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
        );
  }
}
