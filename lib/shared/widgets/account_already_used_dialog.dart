import 'package:flutter/material.dart';

/// Message renvoyé par l'API lorsque les informations d'inscription
/// appartiennent à un compte déjà finalisé.
const String accountAlreadyUsedMessage =
    'Les informations saisies sont déjà utilisées par un autre utilisateur';

bool isAccountAlreadyUsedMessage(String? message) =>
    message?.trim() == accountAlreadyUsedMessage;

/// Informe l'utilisateur que le compte existe déjà et propose d'aller à la
/// page de connexion.
Future<void> showAccountAlreadyUsedDialog(
  BuildContext context, {
  required VoidCallback onLogin,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Compte existant'),
      content: const Text(accountAlreadyUsedMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Fermer'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            onLogin();
          },
          child: const Text('Se connecter'),
        ),
      ],
    ),
  );
}
