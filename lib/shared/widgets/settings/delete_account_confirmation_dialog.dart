library;

import 'package:flutter/material.dart';

import '../confirmation_action_column.dart';
import '../fraya_button.dart';

Future<bool> showDeleteAccountConfirmationDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cette action supprimera votre compte Fraya Taxi. Voulez-vous continuer ?',
            ),
            const SizedBox(height: 20),
            ConfirmationActionColumn(
              primaryLabel: 'Supprimer',
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
