import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/database/database_tables.dart';
import '../../../../core/network/supabase_config.dart';
import '../models/profile_model.dart';

/// Lớp xử lý xác thực (Firebase Auth) và đồng bộ hồ sơ lên Supabase
/// theo kiến trúc 3 bảng: `users` -> `user_accounts` (1-N) & `profiles` (1-1).
class AuthRepository {
  AuthRepository({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn();

  final GoogleSignIn _googleSignIn;

  FirebaseAuth _requireFirebaseAuth() {
    if (Firebase.apps.isEmpty) {
      throw StateError(
        'Chưa cấu hình Firebase (google-services.json). '
        'Vui lòng khởi tạo Firebase trước khi đăng nhập.',
      );
    }
    return FirebaseAuth.instance;
  }

  /// Đăng nhập bằng Email & Mật khẩu qua Firebase Auth
  Future<ProfileModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _requireFirebaseAuth();
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final fbUser = credential.user!;
    return _syncToSupabase(
      firebaseUid: fbUser.uid,
      provider: 'email',
      providerAccountId: fbUser.uid,
      displayName: fbUser.displayName ?? email.split('@').first,
      email: fbUser.email,
      avatarUrl: fbUser.photoURL,
    );
  }

  /// Đăng ký tài khoản mới bằng Email & Mật khẩu
  Future<ProfileModel> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final auth = _requireFirebaseAuth();
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final fbUser = credential.user!;
    await fbUser.updateDisplayName(displayName.trim());

    return _syncToSupabase(
      firebaseUid: fbUser.uid,
      provider: 'email',
      providerAccountId: fbUser.uid,
      displayName: displayName.trim(),
      email: fbUser.email,
      avatarUrl: fbUser.photoURL,
    );
  }

  /// Đăng nhập một chạm bằng tài khoản Google (Firebase Auth + Google Sign-In)
  Future<ProfileModel> signInWithGoogle() async {
    final auth = _requireFirebaseAuth();
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw StateError('Người dùng đã hủy đăng nhập Google.');
    }

    final googleAuth = await googleUser.authentication;
    final oauthCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await auth.signInWithCredential(oauthCredential);
    final fbUser = userCredential.user!;

    return _syncToSupabase(
      firebaseUid: fbUser.uid,
      provider: 'google',
      providerAccountId: fbUser.uid,
      displayName: fbUser.displayName ?? 'Người dùng BuddyTalk',
      email: fbUser.email,
      avatarUrl: fbUser.photoURL,
      isVerified: true,
    );
  }

  /// Đăng xuất khỏi Firebase và Google
  Future<void> signOut() async {
    if (Firebase.apps.isNotEmpty) {
      await FirebaseAuth.instance.signOut();
    }
    await _googleSignIn.signOut();
  }

  /// Đồng bộ tài khoản Firebase vào 3 bảng `users`, `user_accounts`, `profiles` trên Supabase
  Future<ProfileModel> _syncToSupabase({
    required String firebaseUid,
    required String provider,
    required String providerAccountId,
    required String displayName,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    bool isVerified = false,
  }) async {
    final client = SupabaseConfig.clientOrNull;

    // Nếu chưa cấu hình Supabase key, trả về hồ sơ cục bộ để app vẫn test UI mượt
    if (client == null) {
      return ProfileModel(
        userId: firebaseUid,
        displayName: displayName,
        avatarUrl: avatarUrl,
        isOnline: true,
      );
    }

    // 1. Tra cứu xem tài khoản đăng nhập này đã tồn tại trong `user_accounts` chưa
    final existingAccount = await client
        .from(DatabaseTables.userAccounts)
        .select('user_id')
        .eq('provider', provider)
        .eq('provider_account_id', providerAccountId)
        .maybeSingle();

    String internalUserId;

    if (existingAccount != null) {
      internalUserId = existingAccount['user_id'].toString();
      await client
          .from(DatabaseTables.userAccounts)
          .update({'last_login_at': DateTime.now().toIso8601String()})
          .eq('provider', provider)
          .eq('provider_account_id', providerAccountId);
    } else {
      // 2. Tạo user gốc mới trong `users`
      final createdUser = await client
          .from(DatabaseTables.users)
          .insert({'status': 'active', 'role': 'user'})
          .select('id')
          .single();

      internalUserId = createdUser['id'].toString();

      // 3. Tạo bản ghi phương thức đăng nhập trong `user_accounts`
      await client.from(DatabaseTables.userAccounts).insert({
        'user_id': internalUserId,
        'provider': provider,
        'provider_account_id': providerAccountId,
        'firebase_uid': firebaseUid,
        'email': email,
        'phone_number': phoneNumber,
        'is_verified': isVerified,
      });

      // 4. Tạo hồ sơ công khai 1-1 trong `profiles`
      await client.from(DatabaseTables.profiles).insert({
        'user_id': internalUserId,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'is_online': true,
      });
    }

    final profileMap = await client
        .from(DatabaseTables.profiles)
        .select()
        .eq('user_id', internalUserId)
        .single();

    return ProfileModel.fromMap(profileMap);
  }
}
