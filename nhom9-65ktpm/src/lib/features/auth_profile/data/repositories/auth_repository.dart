import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/database/database_tables.dart';
import '../../../../core/network/supabase_config.dart';
import '../models/profile_model.dart';

/// Lớp xử lý xác thực (Firebase Auth) và đồng bộ 100% trực tuyến lên Supabase
/// theo kiến trúc 3 bảng: `users` -> `user_accounts` (1-N) & `profiles` (1-1).
class AuthRepository {
  AuthRepository({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn();

  final GoogleSignIn _googleSignIn;

  FirebaseAuth _requireFirebaseAuth() {
    if (Firebase.apps.isEmpty) {
      throw StateError(
        'Chưa cấu hình Firebase. Vui lòng điền biến FIREBASE_* trong .env '
        'và chạy lại với --dart-define-from-file=.env.',
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

  /// Đăng ký tài khoản mới kèm hồ sơ ngôn ngữ, avatar & mục tiêu kỷ luật hàng ngày
  Future<ProfileModel> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
    String? avatarUrl,
    required String nativeLang,
    required String targetLang,
    required String proficiencyLevel,
    required int dailyGoalMinutes,
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
      avatarUrl: avatarUrl ?? fbUser.photoURL,
      nativeLang: nativeLang,
      targetLang: targetLang,
      proficiencyLevel: proficiencyLevel,
      dailyGoalMinutes: dailyGoalMinutes,
    );
  }

  /// Đăng nhập một chạm bằng tài khoản Google (chạy mượt cả Chrome Web & Android)
  Future<ProfileModel> signInWithGoogle() async {
    final auth = _requireFirebaseAuth();
    late final UserCredential userCredential;

    if (kIsWeb) {
      // Trên Chrome Web: dùng popup chuẩn của Firebase Auth (không cần thêm meta client-id)
      userCredential = await auth.signInWithPopup(GoogleAuthProvider());
    } else {
      // Trên Android / iOS: dùng native GoogleSignIn
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw StateError('Người dùng đã hủy đăng nhập Google.');
      }
      final googleAuth = await googleUser.authentication;
      final oauthCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      userCredential = await auth.signInWithCredential(oauthCredential);
    }

    final fbUser = userCredential.user!;

    return _syncToSupabase(
      firebaseUid: fbUser.uid,
      provider: 'google',
      providerAccountId: fbUser.uid,
      displayName: fbUser.displayName ?? fbUser.email ?? 'BuddyTalk User',
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
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }

  /// Đồng bộ trực tiếp lên CSDL trực tuyến Supabase (không dùng dữ liệu cục bộ/giả lập)
  Future<ProfileModel> _syncToSupabase({
    required String firebaseUid,
    required String provider,
    required String providerAccountId,
    required String displayName,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    String nativeLang = 'vi',
    String targetLang = 'en',
    String proficiencyLevel = 'A1',
    int dailyGoalMinutes = 15,
    bool isVerified = false,
  }) async {
    final client = SupabaseConfig.client;

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
      final createdUser = await client
          .from(DatabaseTables.users)
          .insert({'status': 'active', 'role': 'user'})
          .select('id')
          .single();

      internalUserId = createdUser['id'].toString();

      await client.from(DatabaseTables.userAccounts).insert({
        'user_id': internalUserId,
        'provider': provider,
        'provider_account_id': providerAccountId,
        'firebase_uid': firebaseUid,
        'email': email,
        'phone_number': phoneNumber,
        'is_verified': isVerified,
      });

      await client.from(DatabaseTables.profiles).insert({
        'user_id': internalUserId,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'native_lang': nativeLang,
        'target_lang': targetLang,
        'proficiency_level': proficiencyLevel,
        'daily_goal_minutes': dailyGoalMinutes,
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
