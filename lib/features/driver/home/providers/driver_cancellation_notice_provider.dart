import 'package:flutter_riverpod/legacy.dart';

/// Dernière annulation de course par le passager, gardée à l'écran jusqu'à ce que le chauffeur la ferme :
/// la fenêtre d'alerte peut être manquée ou affichée sans motif quand l'annulation est détectée d'abord
/// par le rafraîchissement de la course.
class DriverCancellationNotice {
  const DriverCancellationNotice({
    required this.rideId,
    required this.reason,
    required this.at,
  });

  final String rideId;
  final String? reason;
  final DateTime at;

  /// Le serveur envoie « Course annulée » quand le passager n'a donné aucun motif : ce n'est pas un motif.
  static const String genericReason = 'Course annulée';

  static String? cleanReason(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    if (text.toLowerCase() == genericReason.toLowerCase()) return null;
    return text;
  }
}

final driverCancellationNoticeProvider =
    StateProvider<DriverCancellationNotice?>((ref) => null);
