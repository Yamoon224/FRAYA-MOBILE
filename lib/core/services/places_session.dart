import 'dart:math';

/// Gère le session token Google Places d'une recherche d'adresse.
///
/// Une session = toutes les frappes d'autocomplete + UN appel Place Details qui
/// la clôture, avec le même token. Google facture alors la session une seule
/// fois au lieu de chaque frappe. Un token n'est jamais réutilisé après la
/// clôture (un token réutilisé invalide la session et refacture à l'unité), et
/// expire côté Google après environ 3 minutes d'inactivité.
class PlacesSession {
  PlacesSession({
    Duration maxAge = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _maxAge = maxAge,
       _now = now ?? DateTime.now;

  /// Instance partagée par toute l'application : le service Places est recréé
  /// par Riverpod, la session doit survivre à ces recréations.
  static final PlacesSession shared = PlacesSession();

  final Duration _maxAge;
  final DateTime Function() _now;
  final Random _random = Random.secure();

  String? _token;
  DateTime? _startedAt;

  /// Token de la session courante ; en démarre une nouvelle si besoin.
  String current() {
    final startedAt = _startedAt;
    if (_token == null ||
        startedAt == null ||
        _now().difference(startedAt) > _maxAge) {
      _token = _generate();
      _startedAt = _now();
    }
    return _token!;
  }

  /// Token à joindre à l'appel Place Details qui clôture la session, ou null si
  /// aucune recherche n'est en cours (le lieu vient alors d'ailleurs).
  /// La session est terminée dans tous les cas : le token ne sert qu'une fois.
  String? close() {
    final startedAt = _startedAt;
    final token = _token;
    _token = null;
    _startedAt = null;
    if (token == null || startedAt == null) return null;
    if (_now().difference(startedAt) > _maxAge) return null;
    return token;
  }

  String _generate() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // UUID v4
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
