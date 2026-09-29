library;

import 'package:flutter/material.dart';

import '../confirmation_action_column.dart';
import '../fraya_button.dart';

Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Voulez-vous vraiment vous déconnecter de votre compte Fraya Taxi ?',
            ),
            const SizedBox(height: 20),
            ConfirmationActionColumn(
              primaryLabel: 'Déconnexion',
              primaryVariant: FrayaButtonVariant.danger,
              onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
              secondaryLabel: 'Annuler',
              onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
            ),
          ],
        ),
      );
    },
  );
  return confirmed ?? false;
}
