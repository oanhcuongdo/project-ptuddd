import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth? _customAuth;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthService({FirebaseAuth? firebaseAuth}) : _customAuth = firebaseAuth;

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  User? get currentUser => _auth?.currentUser;

  bool get isSignedIn => _auth?.currentUser != null;

  /// Đăng nhập bằng tài khoản Google tích hợp với Firebase Auth
  Future<UserCredential?> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase chưa được khởi tạo.');
    }
    try {
      if (kIsWeb) {
        // Trên nền tảng Web: Sử dụng GoogleAuthProvider pop-up
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        return await auth.signInWithPopup(googleProvider);
      } else {
        // Trên nền tảng Di động (Android / iOS): Sử dụng google_sign_in native
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          // Người dùng hủy đăng nhập
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }

  /// Đăng xuất khỏi Firebase và Google
  Future<void> signOut() async {
    try {
      final auth = _auth;
      if (auth != null) {
        await auth.signOut();
      }
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Lỗi đăng xuất: $e');
      rethrow;
    }
  }
}
