import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../models/user.dart';

/// Lỗi nghiệp vụ có message hiển thị được cho người dùng.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// UC-01: đăng nhập / đăng ký / đăng xuất / lấy hồ sơ.
class AuthRepository {
  Future<UserModel?> fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (data == null) return null;

    return UserModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AppException(_authMessage(e));
    } catch (_) {
      throw const AppException(
        'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.',
      );
    }

    final profile = await fetchProfile();
    if (profile == null) {
      await signOut();
      throw const AppException(
        'Không tìm thấy hồ sơ người dùng. Liên hệ quản trị viên.',
      );
    }
    if (profile.isBanned) {
      await signOut();
      throw const AppException(
        'Tài khoản của bạn đã bị khóa do vi phạm chính sách.',
      );
    }

    return profile;
  }

  /// Trả về true nếu đã có phiên đăng nhập ngay,
  /// false nếu Supabase yêu cầu xác nhận email.
  Future<bool> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final result = await supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'role': role,
        },
      );
      return result.session != null;
    } on AuthException catch (e) {
      throw AppException(_authMessage(e));
    } catch (_) {
      throw const AppException(
        'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.',
      );
    }
  }

  Future<void> signOut() => supabase.auth.signOut();

  String _authMessage(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Email này đã được đăng ký tài khoản khác.';
      case 'weak_password':
        return 'Mật khẩu quá yếu, tối thiểu 6 ký tự.';
      case 'over_email_send_rate_limit':
        return 'Bạn thao tác quá nhanh, vui lòng thử lại sau ít phút.';
      case 'email_not_confirmed':
        return 'Email chưa được xác nhận. Kiểm tra hộp thư của bạn.';
    }
    if (e.message.toLowerCase().contains('already registered')) {
      return 'Email này đã được đăng ký tài khoản khác.';
    }
    return e.message;
  }
}
