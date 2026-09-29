
/// États possibles pour l'authentification.
enum AuthStatus { idle, loading, authenticated, unauthenticated, error, wrongRole }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? userData;

  AuthState({
    this.status = AuthStatus.idle,
    this.errorMessage,
    this.userData,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    Map<String, dynamic>? userData,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userData: userData ?? this.userData,
    );
  }
}
