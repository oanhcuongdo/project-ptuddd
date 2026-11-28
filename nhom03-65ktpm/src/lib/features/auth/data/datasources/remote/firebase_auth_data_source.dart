import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../core/error/failure.dart';
import 'auth_failure_mapper.dart';

/// Bọc [FirebaseAuth] và chỉ ném ra [Failure] cho tầng trên.
///
/// Mọi exception của Firebase đều được dịch ở đây, nên `presentation` không bao
/// giờ nhìn thấy `FirebaseAuthException`.
class FirebaseAuthDataSource {
  FirebaseAuthDataSource(this._auth);

  final FirebaseAuth _auth;

  /// Stream phiên đăng nhập; Firebase tự khôi phục phiên đã lưu trên máy nên
  /// app mở lại vẫn vào thẳng màn hình chính khi còn phiên.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> signIn({required String email, required String password}) {
    return _run(
      () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<User> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final user = await _run(
      () => _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      try {
        await user.updateDisplayName(name);
        await user.reload();
      } on FirebaseAuthException catch (error) {
        // Tạo tài khoản đã thành công; chỉ tên hiển thị bị lỗi nên không chặn
        // luồng đăng ký, người dùng có thể đổi tên sau.
        throw mapFirebaseAuthException(error);
      }
    }
    return _auth.currentUser ?? user;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    } catch (error) {
      throw mapFirebaseAuthFailure(error);
    }
  }

  Future<User> _run(Future<UserCredential> Function() action) async {
    try {
      final credential = await action();
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Không thể xác thực. Vui lòng thử lại.');
      }
      return user;
    } on FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    } on Failure {
      rethrow;
    } catch (error) {
      throw mapFirebaseAuthFailure(error);
    }
  }
}
