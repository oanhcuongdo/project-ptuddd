import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/database/database_tables.dart';
import '../../../../core/network/supabase_config.dart';
import '../models/language_model.dart';
import '../models/profile_model.dart';

/// Lớp xử lý xác thực (Firebase Auth) và đồng bộ 100% trực tuyến lên Supabase
/// theo kiến trúc: `users` -> `user_accounts` (1-N), `profiles` (1-1), `languages`.
class AuthRepository {
  AuthRepository({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn();

  final GoogleSignIn _googleSignIn;

  /// Kiểm tra Firebase và Supabase đã sẵn sàng để khôi phục phiên chưa
  bool get canRestoreSession =>
      Firebase.apps.isNotEmpty && SupabaseConfig.isConfigured;

  FirebaseAuth _requireFirebaseAuth() {
    if (Firebase.apps.isEmpty) {
      throw StateError(
        'Chưa cấu hình Firebase. Vui lòng điền biến FIREBASE_* trong .env '
        'và chạy lại với --dart-define-from-file=.env.',
      );
    }
    return FirebaseAuth.instance;
  }

  /// Khôi phục phiên đăng nhập khi F5 / mở lại ứng dụng từ Refresh Token của Firebase
  /// rồi tải lại hồ sơ người dùng từ Supabase.
  Future<ProfileModel?> restoreSession() async {
    if (!canRestoreSession) return null;

    final auth = FirebaseAuth.instance;
    final fbUser = auth.currentUser ??
        await auth.authStateChanges().first.timeout(
              const Duration(seconds: 5),
              onTimeout: () => null,
            );

    if (fbUser == null) return null;

    try {
      // Đảm bảo ID Token còn hiệu lực (Firebase tự dùng Refresh Token cấp mới nếu hết hạn)
      await fbUser.getIdToken();
    } on FirebaseAuthException {
      await auth.signOut();
      return null;
    }

    final client = SupabaseConfig.client;
    final account = await client
        .from(DatabaseTables.userAccounts)
        .select('user_id, provider, provider_account_id')
        .eq('firebase_uid', fbUser.uid)
        .maybeSingle();

    if (account != null) {
      final userId = account['user_id'].toString();
      await client
          .from(DatabaseTables.profiles)
          .update({'is_online': true}).eq('user_id', userId);

      final profileMap = await client
          .from(DatabaseTables.profiles)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (profileMap != null) {
        return ProfileModel.fromMap(profileMap);
      }
    }

    // Tự đồng bộ lại nếu Firebase còn phiên nhưng chưa có bản ghi tương ứng trên Supabase
    final isGoogle = fbUser.providerData.any(
      (info) => info.providerId == 'google.com',
    );
    return _syncToSupabase(
      firebaseUid: fbUser.uid,
      provider: isGoogle ? 'google' : 'email',
      providerAccountId: fbUser.uid,
      displayName: fbUser.displayName ??
          fbUser.email?.split('@').first ??
          'BuddyTalk User',
      email: fbUser.email,
      avatarUrl: fbUser.photoURL,
      isVerified: fbUser.emailVerified || isGoogle,
    );
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
      displayName: fbUser.displayName ?? email.trim().split('@').first,
      email: fbUser.email,
      avatarUrl: fbUser.photoURL,
    );
  }

  /// Đăng ký tài khoản mới chỉ với Email & Mật khẩu:
  /// tạo tài khoản Firebase + khởi tạo hồ sơ chưa setup (`onboarding_completed = false`),
  /// sau đó đăng xuất ngay để người dùng quay về màn Đăng nhập.
  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _requireFirebaseAuth();
    final trimmedEmail = email.trim();
    final credential = await auth.createUserWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );
    final fbUser = credential.user!;

    await _syncToSupabase(
      firebaseUid: fbUser.uid,
      provider: 'email',
      providerAccountId: fbUser.uid,
      displayName: '',
      email: fbUser.email ?? trimmedEmail,
      onboardingCompleted: false,
      isOnline: false,
    );

    // Đăng xuất ngay để chuyển về màn Đăng nhập bắt người dùng đăng nhập lại
    await auth.signOut();
  }

  /// Đăng nhập một chạm bằng tài khoản Google (chạy mượt cả Chrome Web & Android)
  Future<ProfileModel> signInWithGoogle() async {
    final auth = _requireFirebaseAuth();
    late final UserCredential userCredential;

    if (kIsWeb) {
      // Ép Google luôn mở màn hình chọn tài khoản (tránh tự động đăng nhập lại Gmail cũ sau khi đăng xuất)
      final googleProvider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      try {
        userCredential = await auth.signInWithPopup(googleProvider);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'popup-closed-by-user' ||
            e.code == 'cancelled-popup-request') {
          throw StateError('Bạn đã đóng cửa sổ chọn tài khoản Google.');
        }
        rethrow;
      }
    } else {
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

  /// Tải danh sách ngôn ngữ được Admin cấp phép (`is_active = true`) trực tiếp từ Supabase
  Future<List<LanguageModel>> fetchAllowedLanguages() async {
    final client = SupabaseConfig.client;
    final rows = await client
        .from(DatabaseTables.languages)
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return rows
        .map<LanguageModel>((row) => LanguageModel.fromMap(row))
        .toList();
  }

  /// Lưu kết quả thiết lập hồ sơ (Onboarding) lên bảng `profiles` trên Supabase
  Future<ProfileModel> completeOnboarding({
    required String userId,
    required String displayName,
    String? avatarUrl,
    String? nativeLang,
    required String targetLang,
    required String proficiencyLevel,
    required int dailyGoalMinutes,
  }) async {
    final client = SupabaseConfig.client;
    final payload = <String, dynamic>{
      'display_name': displayName.trim(),
      'avatar_url': avatarUrl,
      'target_lang': targetLang,
      'proficiency_level': proficiencyLevel,
      'daily_goal_minutes': dailyGoalMinutes,
      'onboarding_completed': true,
      'is_online': true,
    };
    if (nativeLang != null) {
      payload['native_lang'] = nativeLang;
    }

    final updated = await client
        .from(DatabaseTables.profiles)
        .update(payload)
        .eq('user_id', userId)
        .select()
        .single();

    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.currentUser!
          .updateDisplayName(displayName.trim());
    }

    return ProfileModel.fromMap(updated);
  }

  /// Đăng xuất hoàn toàn khỏi Firebase, Google và cập nhật trạng thái offline trên Supabase
  Future<void> signOut({String? userId}) async {
    if (userId != null && SupabaseConfig.isConfigured) {
      try {
        await SupabaseConfig.client
            .from(DatabaseTables.profiles)
            .update({'is_online': false}).eq('user_id', userId);
      } catch (_) {
        // Không chặn luồng đăng xuất nếu mất mạng
      }
    }
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
    bool onboardingCompleted = false,
    bool isOnline = true,
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
      await client
          .from(DatabaseTables.profiles)
          .update({'is_online': isOnline}).eq('user_id', internalUserId);
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
        'onboarding_completed': onboardingCompleted,
        'is_online': isOnline,
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
