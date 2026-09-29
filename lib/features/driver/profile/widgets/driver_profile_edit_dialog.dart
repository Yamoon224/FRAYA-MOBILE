import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_snack_bar.dart';
import '../../auth/providers/driver_auth_provider.dart';
import '../providers/driver_profile_provider.dart';

class DriverProfileEditDialog extends ConsumerStatefulWidget {
  const DriverProfileEditDialog({super.key});

  @override
  ConsumerState<DriverProfileEditDialog> createState() =>
      _DriverProfileEditDialogState();
}

class _DriverProfileEditDialogState
    extends ConsumerState<DriverProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final userData = ref.read(driverAuthProvider).userData ?? {};
    _firstNameController = TextEditingController(
      text: userData['firstNames']?.toString() ??
          userData['firstName']?.toString() ??
          '',
    );
    _lastNameController = TextEditingController(
      text: userData['lastName']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: userData['email']?.toString() ?? '',
    );
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
    ref.listen(driverProfileControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next.success) {
        ref.read(driverProfileControllerProvider.notifier).clearFeedback();
        Navigator.of(context).pop();
        AppSnackBar.showSuccess(context, 'Profil mis à jour');
      } else if (next.errorMessage != null) {
        ref.read(driverProfileControllerProvider.notifier).clearFeedback();
        AppSnackBar.showError(context, next.errorMessage!);
      }
    });

    final isSubmitting = ref.watch(
      driverProfileControllerProvider.select((s) => s.isSubmitting),
    );

    return AlertDialog(
      title: const Text('Modifier le profil'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SingleChildScrollView(
        child: Form(
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submit,
          child: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: validator,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(driverProfileControllerProvider.notifier).updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
        );
  }
}
