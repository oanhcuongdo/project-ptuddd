class AuthSession {
  const AuthSession({required this.uid, this.email});

  final String uid;
  final String? email;
}

enum AuthFailure implements Exception {
  invalidCredentials,
  invalidEmail,
  weakPassword,
  emailAlreadyInUse,
  accountDisabled,
  network,
  rateLimited,
  googleCanceled,
  providerUnavailable,
  emailSignInRequired,
  sessionExpired,
  awaitingDataAccess,
  unexpected,
}

abstract interface class AuthRepository {
  Stream<AuthSession?> get sessions;

  Future<void> signInWithEmail(String email, String password);
  Future<void> registerWithEmail(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<bool> hasDataAccess({bool refresh = false});
}
