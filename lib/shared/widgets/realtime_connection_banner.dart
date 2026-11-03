library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/socket_health_state.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/realtime_providers.dart';

/// Texte du bandeau côté chauffeur : ses positions sont mises en file puis renvoyées.
const String kDriverConnectionBannerMessage =
    'Connexion instable : les positions sont conservées et seront envoyées '
    'dès le retour du réseau';

/// Texte du bandeau côté passager : la position du chauffeur arrive via le temps réel.
const String kPassengerConnectionBannerMessage =
    'Connexion instable : la position du chauffeur peut être retardée';

/// Bandeau discret « connexion instable », affiché seulement pendant une course active
/// quand le temps réel est dégradé ou hors ligne ; il disparaît au retour de `connected`.
class RealtimeConnectionBanner extends ConsumerWidget {
  const RealtimeConnectionBanner({
    super.key,
    required this.isRideActive,
    required this.message,
  });

  final bool isRideActive;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(realtimeHealthStateProvider);
    final unstable =
        health == SocketHealthState.degraded ||
        health == SocketHealthState.offline;
    if (!isRideActive || !unstable) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: const Color(0xFFB45309),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.small.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
