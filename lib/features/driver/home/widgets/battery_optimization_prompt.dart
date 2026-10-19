library;

import 'package:flutter/material.dart';

import '../../../../core/services/battery_optimization_service.dart';
import '../../../../data/sources/local_storage.dart';

const String _promptShownKey = 'battery_optimization_prompt_shown';

/// Propose, une seule fois, de désactiver l'optimisation de batterie pour que l'app reste active
/// en arrière-plan. Ne fait rien si l'app est déjà exemptée ou si le message a déjà été montré.
Future<void> maybeShowBatteryOptimizationPrompt(
  BuildContext context, {
  BatteryOptimizationService? service,
}) async {
  final battery = service ?? PlatformBatteryOptimizationService();
  try {
    if (await LocalStorage.instance.getSecure(_promptShownKey) == '1') return;
    if (await battery.isIgnoringOptimizations()) return;
    if (!context.mounted) return;

    await LocalStorage.instance.setSecure(_promptShownKey, '1');
    if (!context.mounted) return;
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rester disponible'),
        content: const Text(
          'Pour continuer à recevoir des courses quand l\'application est en arrière-plan, '
          'désactivez l\'optimisation de la batterie pour Fraya Chauffeur '
          'et choisissez « Ne pas optimiser ».',
        ),
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
