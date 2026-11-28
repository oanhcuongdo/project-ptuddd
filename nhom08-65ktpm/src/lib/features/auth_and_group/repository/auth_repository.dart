import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/services/supabase_storage_service.dart';
import '../../../models/app_user.dart';

/// Friendly authentication failure exposed to the UI layer.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();
  AppUser? get currentUser;

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppUser?> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();

  Future<AppUser?> reloadCurrentUser();

  Future<AppUser> updateProfile({
    required String displayName,
    String? phoneNumber,
    Uint8List? avatarBytes,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Firebase.apps.isEmpty) {
    return InMemoryAuthRepository();
  }
  return FirebaseAuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    storageService: ref.watch(supabaseStorageServiceProvider),
  );
});

class FirebaseAuthRepository implements AuthRepository {
  static const String _webServerClientId =
      '498748171599-8aebndc2h4trrq910jo19aikrj0shk6c.apps.googleusercontent.com';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SupabaseStorageService _storageService;
  Future<void>? _googleInitFuture;
  AppUser? _cachedUser;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    SupabaseStorageService? storageService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? SupabaseStorageService();

  CollectionReference<Map<String, dynamic>> get _usersColl =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _userEmailsColl =>
      _firestore.collection('user_emails');

  String _emailKey(String email) =>
      email.trim().toLowerCase().replaceAll('/', '_');

  String _resolveProvider(User user) {
    final hasGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    final hasPassword = user.providerData.any((p) => p.providerId == 'password');
    if (hasGoogle && !hasPassword) return 'google';
    return 'email';
  }

  bool _resolveVerified(User user) {
    final provider = _resolveProvider(user);
    return provider == 'google' || user.emailVerified;
  }

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return _cachedUser;
    if (_cachedUser != null && _cachedUser!.uid == user.uid) {
      return _cachedUser!.copyWith(
        emailVerified: _resolveVerified(user),
        authProvider: _resolveProvider(user),
      );
    }
    final now = DateTime.now();
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: _resolveDisplayName(user),
      avatarUrl: user.photoURL,
      phoneNumber: user.phoneNumber,
      authProvider: _resolveProvider(user),
      emailVerified: _resolveVerified(user),
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Stream<AppUser?> watchAuthState() {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        _cachedUser = null;
        return Stream<AppUser?>.value(null);
      }
      return _usersColl.doc(firebaseUser.uid).snapshots().asyncMap((doc) async {
        final verified = _resolveVerified(firebaseUser);
        final provider = _resolveProvider(firebaseUser);
        if (doc.exists && doc.data() != null) {
          final parsed = AppUser.fromJson({...doc.data()!, 'uid': doc.id})
              .copyWith(emailVerified: verified, authProvider: provider);
          _cachedUser = parsed;
          return parsed;
        }
        return _syncUserDocument(firebaseUser);
      });
    });
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Không thể lấy thông tin tài khoản sau khi đăng nhập.');
      }
      await _recordEmailProvider(
        email: email,
        uid: user.uid,
        provider: _resolveProvider(user),
      );
      return await _syncUserDocument(user);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    }
  }

  @override
  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final emailDoc = await _userEmailsColl.doc(_emailKey(normalizedEmail)).get();
      if (emailDoc.exists) {
        final provider = emailDoc.data()?['provider'] as String?;
        if (provider == 'google') {
          throw const AuthFailure(
            'Email này đã đăng ký bằng Google Sign-In. Vui lòng chọn "Tiếp tục với Google".',
          );
        }
        throw const AuthFailure('Email này đã được đăng ký tài khoản.');
      }
    } on FirebaseException catch (e) {
      debugPrint('user_emails lookup skipped: ${e.message}');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Không thể tạo tài khoản mới.');
      }
      final trimmedName = displayName.trim();
      if (trimmedName.isNotEmpty) {
        await user.updateDisplayName(trimmedName);
      }
      try {
        await user.sendEmailVerification();
      } catch (e) {
        debugPrint('sendEmailVerification skipped: $e');
      }
      await _recordEmailProvider(
        email: normalizedEmail,
        uid: user.uid,
        provider: 'email',
      );
      return await _syncUserDocument(user, overrideDisplayName: trimmedName);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    }
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      User? firebaseUser;
      if (kIsWeb) {
        final result = await _auth.signInWithPopup(GoogleAuthProvider());
        firebaseUser = result.user;
      } else {
        await _ensureGoogleInitialized();
        if (!GoogleSignIn.instance.supportsAuthenticate()) {
          final result = await _auth.signInWithProvider(GoogleAuthProvider());
          firebaseUser = result.user;
        } else {
          final account = await GoogleSignIn.instance.authenticate();
          final idToken = account.authentication.idToken;
          final authorization = await account.authorizationClient
              .authorizationForScopes(const ['email', 'profile']);
          if (idToken == null && authorization == null) {
            throw const AuthFailure('Không lấy được mã xác thực từ Google.');
          }
          final oauthCredential = GoogleAuthProvider.credential(
            idToken: idToken,
            accessToken: authorization?.accessToken,
          );
          final result = await _auth.signInWithCredential(oauthCredential);
          firebaseUser = result.user;
        }
      }

      if (firebaseUser == null) return null;
      if ((firebaseUser.email ?? '').isNotEmpty) {
        await _recordEmailProvider(
          email: firebaseUser.email!,
          uid: firebaseUser.uid,
          provider: 'google',
        );
      }
      return await _syncUserDocument(firebaseUser);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw AuthFailure('Đăng nhập Google thất bại: ${e.description ?? e.code.name}');
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('Phiên đăng nhập không hợp lệ.');
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    }
  }

  @override
  Future<AppUser?> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    final reloaded = _auth.currentUser;
    if (reloaded == null) return null;
    return _syncUserDocument(reloaded);
  }

  @override
  Future<AppUser> updateProfile({
    required String displayName,
    String? phoneNumber,
    Uint8List? avatarBytes,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw const AuthFailure('Vui lòng đăng nhập lại để cập nhật hồ sơ.');
    }
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      throw const AuthFailure('Họ và tên không được để trống.');
    }
    try {
      await firebaseUser.updateDisplayName(trimmedName);
      String? avatarUrl = _cachedUser?.avatarUrl ?? firebaseUser.photoURL;
      String? avatarPath = _cachedUser?.avatarStoragePath;
      if (avatarBytes != null) {
        avatarPath =
            'users/${firebaseUser.uid}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        avatarUrl = await _storageService.uploadBytes(
          path: avatarPath,
          bytes: avatarBytes,
        );
        await firebaseUser.updatePhotoURL(avatarUrl);
      }

      final current = await _syncUserDocument(
        firebaseUser,
        overrideDisplayName: trimmedName,
      );
      final updated = current.copyWith(
        displayName: trimmedName,
        phoneNumber: phoneNumber?.trim().isEmpty == true
            ? null
            : phoneNumber?.trim(),
        avatarUrl: avatarUrl,
        avatarStoragePath: avatarPath,
        updatedAt: DateTime.now(),
      );
      await _usersColl.doc(firebaseUser.uid).set(updated.toJson(), SetOptions(merge: true));
      _cachedUser = updated;
      return updated;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || (firebaseUser.email ?? '').isEmpty) {
      throw const AuthFailure('Không tìm thấy thông tin tài khoản.');
    }
    if (_resolveProvider(firebaseUser) != 'email') {
      throw const AuthFailure('Tài khoản Google không hỗ trợ đổi mật khẩu tại đây.');
    }
    try {
      final cred = EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(cred);
      await firebaseUser.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    }
  }

  @override
  Future<void> signOut() async {
    _cachedUser = null;
    if (!kIsWeb && _googleInitFuture != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitFuture ??= GoogleSignIn.instance.initialize(
      serverClientId: _webServerClientId,
    );
  }

  Future<void> _recordEmailProvider({
    required String email,
    required String uid,
    required String provider,
  }) async {
    try {
      await _userEmailsColl.doc(_emailKey(email)).set({
        'email': email.trim().toLowerCase(),
        'uid': uid,
        'provider': provider,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('recordEmailProvider skipped: $e');
    }
  }

  Future<AppUser> _syncUserDocument(
    User firebaseUser, {
    String? overrideDisplayName,
  }) async {
    final docRef = _usersColl.doc(firebaseUser.uid);
    final snapshot = await docRef.get();
    final now = DateTime.now();
    final provider = _resolveProvider(firebaseUser);
    final verified = _resolveVerified(firebaseUser);
    final resolvedName =
        (overrideDisplayName != null && overrideDisplayName.isNotEmpty)
            ? overrideDisplayName
            : _resolveDisplayName(firebaseUser);

    if (snapshot.exists && snapshot.data() != null) {
      final existing = AppUser.fromJson({...snapshot.data()!, 'uid': snapshot.id});
      final updated = existing.copyWith(
        email: firebaseUser.email ?? existing.email,
        displayName: (overrideDisplayName != null && overrideDisplayName.isNotEmpty)
            ? overrideDisplayName
            : (existing.displayName.isNotEmpty ? existing.displayName : resolvedName),
        avatarUrl: existing.avatarUrl ?? firebaseUser.photoURL,
        phoneNumber: existing.phoneNumber ?? firebaseUser.phoneNumber,
        authProvider: provider,
        emailVerified: verified,
        updatedAt: now,
      );
      await docRef.set(updated.toJson(), SetOptions(merge: true));
      _cachedUser = updated;
      return updated;
    }

    final created = AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: resolvedName,
      avatarUrl: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
      authProvider: provider,
      emailVerified: verified,
      tripIds: const [],
      createdAt: now,
      updatedAt: now,
    );
    await docRef.set(created.toJson());
    _cachedUser = created;
    return created;
  }

  String _resolveDisplayName(User user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user.email?.trim() ?? '';
    if (email.contains('@')) return email.split('@').first;
    return 'Thành viên Travel Buddy';
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Địa chỉ email không đúng định dạng.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu chưa chính xác.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký tài khoản.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'requires-recent-login':
        return 'Vui lòng nhập đúng mật khẩu hiện tại để thực hiện thao tác này.';
      case 'too-many-requests':
        return 'Thử quá nhiều lần. Vui lòng đợi giây lát rồi thử lại.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra Internet.';
      default:
        return e.message ?? 'Xác thực thất bại (${e.code}).';
    }
  }
}

/// Offline/preview fallback repository used when Firebase is not initialized.
class InMemoryAuthRepository implements AuthRepository {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _controller = StreamController<AppUser?>.broadcast();
  final Map<String, String> _credentials = {
    'host.test@travelbuddy.vn': 'Test@123456',
    'member.test@travelbuddy.vn': 'Test@123456',
    '2351170568@e.tlu.edu.vn': 'Test@123456',
  };
  final Map<String, String> _displayNames = {
    'host.test@travelbuddy.vn': 'Đỗ Đình An',
    'member.test@travelbuddy.vn': 'Nguyễn Xuân Bình',
    '2351170568@e.tlu.edu.vn': 'Đỗ Đình An',
  };
  final Set<String> _googleEmails = {'google.user@travelbuddy.vn'};
  AppUser? _user;

  InMemoryAuthRepository({bool seedSignedIn = true}) {
    if (seedSignedIn) {
      final now = DateTime.now();
      _user = AppUser(
        uid: 'demo-host-an',
        email: '2351170568@e.tlu.edu.vn',
        displayName: 'Đỗ Đình An',
        authProvider: 'email',
        emailVerified: true,
        tripIds: const ['demo-trip'],
        createdAt: now,
        updatedAt: now,
      );
    }
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchAuthState() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_emailRegex.hasMatch(normalizedEmail)) {
      throw const AuthFailure('Địa chỉ email không đúng định dạng.');
    }
    if (password.length < 6) {
      throw const AuthFailure('Email hoặc mật khẩu chưa chính xác.');
    }
    final expectedPassword = _credentials[normalizedEmail];
    if (expectedPassword != null && expectedPassword != password) {
      throw const AuthFailure('Email hoặc mật khẩu chưa chính xác.');
    }

    final now = DateTime.now();
    final name = _displayNames[normalizedEmail] ??
        (normalizedEmail.contains('@')
            ? normalizedEmail.split('@').first
            : 'Đỗ Đình An');
    final uid = normalizedEmail == 'member.test@travelbuddy.vn'
        ? 'demo-member-binh'
        : 'demo-host-an';
    _user = AppUser(
      uid: uid,
      email: normalizedEmail,
      displayName: name.isEmpty ? 'Đỗ Đình An' : name,
      authProvider: 'email',
      emailVerified: true,
      tripIds: const ['demo-trip'],
      createdAt: now,
      updatedAt: now,
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_emailRegex.hasMatch(normalizedEmail)) {
      throw const AuthFailure('Địa chỉ email không đúng định dạng.');
    }
    if (_googleEmails.contains(normalizedEmail)) {
      throw const AuthFailure(
        'Email này đã đăng ký bằng Google Sign-In. Vui lòng chọn "Tiếp tục với Google".',
      );
    }
    if (password.length < 6) {
      throw const AuthFailure('Mật khẩu quá yếu (tối thiểu 6 ký tự).');
    }
    final trimmedName =
        displayName.trim().isEmpty ? 'Thành viên mới' : displayName.trim();
    _credentials[normalizedEmail] = password;
    _displayNames[normalizedEmail] = trimmedName;

    final now = DateTime.now();
    _user = AppUser(
      uid: 'demo-user-${now.millisecondsSinceEpoch}',
      email: normalizedEmail,
      displayName: trimmedName,
      authProvider: 'email',
      emailVerified: false,
      tripIds: const [],
      createdAt: now,
      updatedAt: now,
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    const email = 'google.user@travelbuddy.vn';
    _googleEmails.add(email);
    final now = DateTime.now();
    _user = AppUser(
      uid: 'demo-host-an',
      email: email,
      displayName: 'Đỗ Đình An',
      authProvider: 'google',
      emailVerified: true,
      tripIds: const ['demo-trip'],
      createdAt: now,
      updatedAt: now,
    );
    _controller.add(_user);
    return _user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<AppUser?> reloadCurrentUser() async {
    if (_user == null) return null;
    _user = _user!.copyWith(emailVerified: true, updatedAt: DateTime.now());
    _controller.add(_user);
    return _user;
  }

  @override
  Future<AppUser> updateProfile({
    required String displayName,
    String? phoneNumber,
    Uint8List? avatarBytes,
  }) async {
    if (_user == null) {
      throw const AuthFailure('Vui lòng đăng nhập lại.');
    }
    _user = _user!.copyWith(
      displayName: displayName.trim(),
      phoneNumber: phoneNumber?.trim().isEmpty == true ? null : phoneNumber?.trim(),
      updatedAt: DateTime.now(),
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null) {
      throw const AuthFailure('Vui lòng đăng nhập lại.');
    }
    if (_user!.authProvider != 'email') {
      throw const AuthFailure('Tài khoản Google không hỗ trợ đổi mật khẩu.');
    }
    final expected = _credentials[_user!.email];
    if (expected != null && expected != currentPassword) {
      throw const AuthFailure('Mật khẩu hiện tại không chính xác.');
    }
    _credentials[_user!.email] = newPassword;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
