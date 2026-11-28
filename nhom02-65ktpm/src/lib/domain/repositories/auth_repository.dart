import '../../core/result.dart';

/// Thông tin tối thiểu về người dùng đã đăng nhập.
class AuthUser {
  const AuthUser({required this.uid, this.email, this.displayName});

  final String uid;
  final String? email;
  final String? displayName;
}

/// Hợp đồng đăng nhập. Tầng Data cài đặt bằng Firebase Auth + Google Sign-In.
abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  Future<Result<void>> signInWithEmail(String email, String password);

  Future<Result<void>> registerWithEmail(String email, String password, String displayName);

  Future<Result<void>> signInWithGoogle();

  Future<Result<void>> sendPasswordReset(String email);

  Future<void> signOut();
}
