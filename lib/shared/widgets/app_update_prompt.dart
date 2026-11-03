library;

import 'package:flutter/material.dart';

import '../../core/services/app_update_service.dart';

/// Une seule proposition par lancement de l'application.
bool _promptedThisSession = false;

/// Propose la mise à jour quand une version plus récente est publiée sur le store.
///
/// [contextProvider] fournit le contexte au moment de l'affichage (le contexte du lancement peut ne plus
/// exister une fois la vérification terminée). « Plus tard » repousse la même version de 24 h.
Future<void> maybeShowAppUpdatePrompt(
  BuildContext? Function() contextProvider, {
  AppUpdateService? service,
}) async {
  if (_promptedThisSession) return;
  final updates = service ?? AppUpdateService();
  final update = await updates.check();
  if (update == null || !await updates.shouldPrompt(update)) return;
  final context = contextProvider();
  if (context == null || !context.mounted || _promptedThisSession) return;
  _promptedThisSession = true;

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
    await updates.startUpdate(update);
  } else {
    await updates.snooze(update);
  }
}

void resetAppUpdatePromptSession() => _promptedThisSession = false;
