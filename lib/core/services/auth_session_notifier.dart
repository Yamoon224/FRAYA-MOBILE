library;

import 'dart:async';

/// Notifie globalement les expirations de session non récupérables.
class AuthSessionNotifier {
  AuthSessionNotifier._();

  static final AuthSessionNotifier _instance = AuthSessionNotifier._();
  static AuthSessionNotifier get instance => _instance;

  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();
  final StreamController<void> _tokenRefreshedController =
      StreamController<void>.broadcast();
  bool _hasNotified = false;

  Stream<String?> get events => _controller.stream;
  Stream<void> get tokenRefreshedEvents => _tokenRefreshedController.stream;

  /// Emet un seul evenement d'expiration tant que [reset] n'est pas appele.
  void notifyExpired([String? message]) {
    if (_hasNotified) return;
    _hasNotified = true;
    _controller.add(message);
  }

  void notifyTokenRefreshed() {
    _tokenRefreshedController.add(null);
  }

  /// Rearme la notification (a appeler apres une authentification reussie).
  void reset() {
    _hasNotified = false;
  }
}
