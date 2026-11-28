import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/result.dart';
import '../../core/strings/app_strings.dart';
import '../../core/strings/auth_strings.dart';
import '../../domain/repositories/auth_repository.dart';

/// Cài đặt [AuthRepository] bằng Firebase Auth (Email/Mật khẩu + Google).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._googleSignIn);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleInit;

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_toAuthUser);

  @override
  AuthUser? get currentUser => _toAuthUser(_auth.currentUser);

  AuthUser? _toAuthUser(User? user) => user == null
      ? null
      : AuthUser(uid: user.uid, email: user.email, displayName: user.displayName);

  @override
  Future<Result<void>> signInWithEmail(String email, String password) {
    return _guard(() => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ));
  }

  @override
  Future<Result<void>> registerWithEmail(String email, String password, String displayName) {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(displayName.trim());
    });
  }

  @override
  Future<Result<void>> signInWithGoogle() async {
    try {
      // google_sign_in v7: initialize() đúng MỘT lần trước mọi thao tác khác.
      // serverClientId được đọc tự động từ google-services.json (web client).
      await (_googleInit ??= _googleSignIn.initialize());
      if (!_googleSignIn.supportsAuthenticate()) {
        return const Err(AppFailure(FailureType.auth, AuthStrings.errGoogleUnavailable));
      }
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
      return const Ok(null);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const Err(AppFailure(FailureType.cancelled));
      }
      debugPrint('Google sign-in error: ${e.code} ${e.description}');
      return Err(AppFailure(FailureType.auth, AuthStrings.errGoogleFailed, e));
    } on FirebaseAuthException catch (e) {
      return Err(_mapAuthError(e));
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return Err(AppFailure(FailureType.unknown, AuthStrings.errGoogleFailed, e));
    }
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) {
    return _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  @override
  Future<void> signOut() async {
    if (_googleInit != null) {
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('Google sign-out error: $e');
      }
    }
    await _auth.signOut();
  }

  Future<Result<void>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return const Ok(null);
    } on FirebaseAuthException catch (e) {
      return Err(_mapAuthError(e));
    } catch (e) {
      return Err(AppFailure(FailureType.unknown, AppStrings.genericError, e));
    }
  }

  AppFailure _mapAuthError(FirebaseAuthException e) {
    final message = switch (e.code) {
      'invalid-email' => AuthStrings.invalidEmail,
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        AuthStrings.errWrongCredential,
      'email-already-in-use' => AuthStrings.errEmailInUse,
      'weak-password' => AuthStrings.errWeakPassword,
      'user-disabled' => AuthStrings.errUserDisabled,
      'too-many-requests' => AuthStrings.errTooManyRequests,
      'network-request-failed' => AppStrings.networkError,
      _ => AppStrings.genericError,
    };
    final type = e.code == 'network-request-failed' ? FailureType.network : FailureType.auth;
    return AppFailure(type, message, e);
  }
}
