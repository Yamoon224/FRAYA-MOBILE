import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/auth_otp_dialog.dart';
import '../providers/driver_profile_provider.dart';

class DriverProfilePhoneChangeDialog extends ConsumerStatefulWidget {
  const DriverProfilePhoneChangeDialog({super.key});

  @override
  ConsumerState<DriverProfilePhoneChangeDialog> createState() =>
      _DriverProfilePhoneChangeDialogState();
}

class _DriverProfilePhoneChangeDialogState
    extends ConsumerState<DriverProfilePhoneChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(driverProfileControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next.errorMessage != null) {
        AppSnackBar.showError(context, next.errorMessage!);
      }
    });

    final isSubmitting = ref.watch(
      driverProfileControllerProvider.select((s) => s.isSubmitting),
    );

    return AlertDialog(
      title: const Text('Modifier le numéro'),
      content: Form(
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
          validator: (v) =>
              (v == null || v.trim().length < 8) ? 'Numéro invalide' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _sendOtp,
          child: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Envoyer le code'),
        ),
      ],
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();

    await ref
        .read(driverProfileControllerProvider.notifier)
        .requestPhoneChange(phone);

    final stateAfterSend = ref.read(driverProfileControllerProvider);
    if (stateAfterSend.errorMessage != null || !mounted) return;

    final notifier = ref.read(driverProfileControllerProvider.notifier);
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
