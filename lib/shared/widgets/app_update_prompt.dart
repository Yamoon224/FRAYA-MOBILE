library;

import 'package:flutter/material.dart';

import '../../core/services/app_update_service.dart';

/// Une proposition à la fois : boîte de dialogue ouverte, ou mise à jour acceptée en cours.
bool _promptedThisSession = false;

/// Évite d'interroger le store à chaque retour au premier plan.
DateTime? _lastCheckAt;
const _minDelayBetweenChecks = Duration(hours: 1);

/// Propose la mise à jour quand une version plus récente est publiée sur le store.
///
/// [contextProvider] fournit le contexte au moment de l'affichage (le contexte du lancement peut ne plus
/// exister une fois la vérification terminée). « Plus tard » repousse la même version de 24 h.
///
/// Renvoie `false` quand une mise à jour est à proposer mais que l'écran n'est pas encore prêt
/// (écran de démarrage, navigation en cours) : l'appelant doit alors réessayer un peu plus tard.
Future<bool> maybeShowAppUpdatePrompt(
  BuildContext? Function() contextProvider, {
  AppUpdateService? service,
  DateTime? now,
}) async {
  if (_promptedThisSession) return true;
  final clock = now ?? DateTime.now();
  final lastCheckAt = _lastCheckAt;
  if (lastCheckAt != null &&
      clock.difference(lastCheckAt) < _minDelayBetweenChecks) {
    return true;
  }

  final updates = service ?? AppUpdateService();
  final update = await updates.check();
  if (update == null || !await updates.shouldPrompt(update, now: now)) {
    _lastCheckAt = clock;
    return true;
  }
  final context = contextProvider();
  if (context == null || !context.mounted) return false;
  if (_promptedThisSession) return true;
  _promptedThisSession = true;
  _lastCheckAt = clock;

  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Mise à jour disponible'),
      content: Text(
        update.storeVersion == null
            ? 'Une nouvelle version de Fraya est disponible. '
                  'Mettez à jour pour profiter des dernières améliorations et corrections.'
            : 'La version ${update.storeVersion} de Fraya est disponible. '
                  'Mettez à jour pour profiter des dernières améliorations et corrections.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Plus tard'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Mettre à jour'),
        ),
      ],
    ),
  );
  if (accepted == true) {
    // Mise à jour acceptée : pas de nouvelle boîte tant que l'application n'est pas relancée.
    await updates.startUpdate(update);
  } else {
    await updates.snooze(update, now: now);
    // « Plus tard » : la même version pourra être reproposée après 24 h, même sans relancer l'application.
    _promptedThisSession = false;
  }
  return true;
}

void resetAppUpdatePromptSession() {
  _promptedThisSession = false;
  _lastCheckAt = null;
}
