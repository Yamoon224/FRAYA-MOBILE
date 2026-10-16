import 'package:flutter/material.dart';

import 'app_snack_bar.dart';

/// Message renvoyé par l'API lorsque les informations d'inscription
/// appartiennent à un compte déjà finalisé.
const String accountAlreadyUsedMessage =
    'Les informations saisies sont déjà utilisées par un autre utilisateur';

bool isAccountAlreadyUsedMessage(String? message) =>
    message?.trim() == accountAlreadyUsedMessage;

/// Message renvoyé par l'API lorsqu'un chauffeur a passé l'inscription mais
/// n'a pas fini le véhicule ou le KYC.
const String driverRegistrationIncompleteMessage =
    "Votre inscription n'est pas terminée. Connectez-vous pour finaliser les étapes restantes.";

bool isDriverRegistrationIncompleteMessage(String? message) =>
    message?.trim() == driverRegistrationIncompleteMessage;

/// Propose au chauffeur de se connecter pour finaliser les étapes restantes ;
/// le routeur l'envoie ensuite directement sur l'étape manquante (véhicule / KYC).
Future<void> showDriverRegistrationIncompleteDialog(
  BuildContext context, {
  required VoidCallback onFinalize,
}) {
  AppSnackBar.dismissCurrentTopOverlay();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Inscription en cours'),
      content: const Text(driverRegistrationIncompleteMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Fermer'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            onFinalize();
          },
          child: const Text('Finaliser les étapes restantes'),
        ),
      ],
    ),
  );
}

/// Informe l'utilisateur que le compte existe déjà et propose d'aller à la
/// page de connexion.
Future<void> showAccountAlreadyUsedDialog(
  BuildContext context, {
  required VoidCallback onLogin,
}) {
  AppSnackBar.dismissCurrentTopOverlay();
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
