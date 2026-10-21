library;

import 'package:flutter/material.dart';

import '../../core/services/pin_migration_service.dart';

/// Une seule invitation par lancement de l'application, même si l'écran d'accueil est reconstruit.
bool _promptedThisSession = false;

enum _PinMigrationChoice { switchNow, alreadyPin, later }

/// Propose le passage au mot de passe à 4 chiffres aux comptes qui ont encore l'ancien format.
///
/// Si l'on sait déjà que la connexion s'est faite avec un ancien mot de passe, l'invitation est directe ;
/// sinon (session ouverte avant la mise à jour) on demande à l'utilisateur quel mot de passe il utilise.
/// [onAccept] ouvre l'écran de changement de mot de passe.
Future<void> maybeShowPinMigrationPrompt(
  BuildContext context, {
  required VoidCallback onAccept,
  PinMigrationService? service,
}) async {
  if (_promptedThisSession) return;
  final migration = service ?? PinMigrationService();
  try {
    if (!migration.shouldPrompt()) return;
    if (!context.mounted) return;
    _promptedThisSession = true;

    final knownLegacy = migration.status == PinMigrationStatus.legacy;
    final choice = await showDialog<_PinMigrationChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mot de passe à 4 chiffres'),
        content: Text(
          knownLegacy
              ? "Fraya passe à un mot de passe de 4 chiffres, plus simple à retenir. "
                    "Vous utilisez encore votre ancien mot de passe : voulez-vous le remplacer par 4 chiffres ?"
              : "Fraya passe à un mot de passe de 4 chiffres, plus simple à retenir. "
                    "Utilisez-vous toujours votre ancien mot de passe ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_PinMigrationChoice.later),
            child: const Text('Plus tard'),
          ),
          if (!knownLegacy)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(_PinMigrationChoice.alreadyPin),
              child: const Text("Non, j'ai déjà 4 chiffres"),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(_PinMigrationChoice.switchNow),
            child: Text(knownLegacy ? 'Passer à 4 chiffres' : 'Oui, passer à 4 chiffres'),
          ),
        ],
      ),
    );

    switch (choice) {
      case _PinMigrationChoice.switchNow:
        // On repose la question plus tard au cas où il abandonne ; le changement réussi la fait cesser.
        await migration.snooze();
        if (context.mounted) onAccept();
      case _PinMigrationChoice.alreadyPin:
        await migration.markDone();
      case _PinMigrationChoice.later:
      case null:
        await migration.snooze();
    }
  } catch (_) {
    // Une invitation facultative ne doit jamais perturber l'écran d'accueil.
  }
}

/// Pour les tests : autorise une nouvelle invitation dans la même session.
@visibleForTesting
void resetPinMigrationPromptSession() => _promptedThisSession = false;
