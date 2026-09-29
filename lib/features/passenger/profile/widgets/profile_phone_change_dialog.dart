import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/auth_otp_dialog.dart';
import '../../../../shared/widgets/confirmation_action_column.dart';
import '../providers/profile_provider.dart';

class ProfilePhoneChangeDialog extends ConsumerStatefulWidget {
  const ProfilePhoneChangeDialog({super.key});

  @override
  ConsumerState<ProfilePhoneChangeDialog> createState() =>
      _ProfilePhoneChangeDialogState();
}

class _ProfilePhoneChangeDialogState
    extends ConsumerState<ProfilePhoneChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next.errorMessage != null) {
        AppSnackBar.showError(context, next.errorMessage!);
      }
    });

    final isSubmitting = ref.watch(
      profileControllerProvider.select((s) => s.isSubmitting),
    );

    return AlertDialog(
      title: const Text('Modifier le numéro'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _phoneController,
                enabled: !isSubmitting,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nouveau numéro de téléphone',
                  hintText: 'Ex: 0700000000',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 8)
                    ? 'Numéro invalide'
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            ConfirmationActionColumn(
              primaryLabel: 'Envoyer le code',
              onPrimaryPressed: _sendOtp,
              secondaryLabel: 'Annuler',
              onSecondaryPressed: () => Navigator.of(context).pop(),
              isSubmitting: isSubmitting,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();

    await ref
        .read(profileControllerProvider.notifier)
        .requestPhoneChange(phone);

    final stateAfterSend = ref.read(profileControllerProvider);
    if (stateAfterSend.errorMessage != null || !mounted) return;

    final notifier = ref.read(profileControllerProvider.notifier);
    notifier.clearFeedback();

    if (!mounted) return;
    Navigator.of(context).pop();

    final confirmed = await showAuthOtpDialog(
      context: context,
      title: 'Vérification',
      description:
          'Entrez le code envoyé par SMS au $phone et à votre adresse email associée.',
      successMessage: 'Numéro mis à jour avec succès',
      onSubmit: (otp) async {
        await notifier.changePhone(phone, otp);
        if (notifier.errorMessage != null) {
          throw Exception(notifier.errorMessage);
        }
      },
      onResend: () async {
        await notifier.requestPhoneChange(phone);
        if (notifier.errorMessage != null) {
          throw Exception(notifier.errorMessage);
        }
      },
    );

    if (confirmed == true) {
      notifier.clearFeedback();
    }
  }
}
