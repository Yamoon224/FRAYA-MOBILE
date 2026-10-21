library;

import 'package:flutter/material.dart';

import '../../core/services/battery_optimization_service.dart';
import '../../data/sources/local_storage.dart';

/// Texte et mémoire d'affichage d'un rappel batterie : un message par type d'application.
class BatteryPromptContent {
  const BatteryPromptContent({
    required this.title,
    required this.message,
    required this.shownKey,
  });

  final String title;
  final String message;
  final String shownKey;

  static const driver = BatteryPromptContent(
    title: 'Rester disponible',
    message:
        "Pour continuer à recevoir des courses quand l'application est en arrière-plan, "
        "désactivez l'optimisation de la batterie pour Fraya Chauffeur "
        'et choisissez « Ne pas optimiser ».',
    shownKey: 'battery_optimization_prompt_shown',
  );

  static const passenger = BatteryPromptContent(
    title: 'Suivre votre course sans interruption',
    message:
        "Pour que Fraya reste actif et vous prévienne dès que votre chauffeur arrive, "
        "désactivez l'optimisation de la batterie pour Fraya "
        'et choisissez « Ne pas optimiser ».',
    shownKey: 'battery_optimization_prompt_shown_passenger',
  );
}

/// Propose, une seule fois, de désactiver l'optimisation de batterie pour que l'app reste active
/// en arrière-plan. Ne fait rien si l'app est déjà exemptée ou si le message a déjà été montré.
Future<void> maybeShowBatteryOptimizationPrompt(
  BuildContext context, {
  BatteryOptimizationService? service,
  BatteryPromptContent content = BatteryPromptContent.driver,
}) async {
  final battery = service ?? PlatformBatteryOptimizationService();
  try {
    if (await LocalStorage.instance.getSecure(content.shownKey) == '1') return;
    if (await battery.isIgnoringOptimizations()) return;
    if (!context.mounted) return;

    await LocalStorage.instance.setSecure(content.shownKey, '1');
    if (!context.mounted) return;
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(content.title),
        content: Text(content.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ouvrir les réglages'),
          ),
        ],
      ),
    );
    if (openSettings == true) await battery.openSettings();
  } catch (_) {
    // Une aide facultative ne doit jamais perturber le passage en ligne.
  }
}
