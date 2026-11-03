library;

/// Position GPS d'une course en cours, mesurée côté client et pas encore acceptée par le serveur.
class QueuedDriverPosition {
  const QueuedDriverPosition({
    required this.rideId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  final String rideId;
  final int driverId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Map<String, dynamic> toPayload() => {
    'driverId': driverId,
    'latitude': latitude,
    'longitude': longitude,
    // Heure de la mesure (pas de l'envoi) : le serveur la garde comme `measuredAt`.
    'timestamp': timestamp.toUtc().toIso8601String(),
  };
}

/// File bornée des positions de course non envoyées (coupure réseau), du plus ancien au plus récent.
///
/// En mémoire seulement : une position de plus de [maxAge] n'a plus d'intérêt pour le suivi,
/// et la file ne survit donc pas utilement à un redémarrage de l'application.
class DriverPositionQueue {
  DriverPositionQueue({
    this.maxEntries = 200,
    this.maxAge = const Duration(minutes: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final int maxEntries;
  final Duration maxAge;
  final DateTime Function() _now;
  final List<QueuedDriverPosition> _entries = <QueuedDriverPosition>[];

  int get length => _entries.length;
  bool get isEmpty => _entries.isEmpty;
  bool get isNotEmpty => _entries.isNotEmpty;

  void add(QueuedDriverPosition position) {
    _entries.add(position);
    // Les plus anciennes sont écartées : ce sont les moins utiles au suivi en direct.
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
  }

  /// Retire les entrées périmées (plus anciennes que [maxAge]).
  void purgeExpired() {
    final limit = _now().subtract(maxAge);
    _entries.removeWhere((entry) => entry.timestamp.isBefore(limit));
  }

  /// Plus ancienne entrée encore valide, sans la retirer ; null si la file est vide.
  QueuedDriverPosition? peek() {
    purgeExpired();
    return _entries.isEmpty ? null : _entries.first;
  }

  /// Retire [position] une fois traitée (envoyée ou refusée définitivement).
  void remove(QueuedDriverPosition position) {
    _entries.remove(position);
  }

  void clear() => _entries.clear();
}
