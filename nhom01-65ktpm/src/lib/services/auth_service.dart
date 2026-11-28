import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

/// Dịch vụ quản lý toàn bộ các tác vụ Xác thực (Authentication) với Supabase
class AuthService {
  final SupabaseClient _client;

  AuthService({SupabaseClient? client}) : _client = client ?? supabase;

  /// Lấy thông tin người dùng / cầu thủ hiện đang đăng nhập
  User? get currentUser => _client.auth.currentUser;

  /// Lấy User ID dạng UUID của người dùng hiện tại
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Kiểm tra xem người dùng đã đăng nhập hay chưa
  bool get isAuthenticated => currentUser != null;

  /// Lắng nghe luồng thay đổi trạng thái đăng nhập / đăng xuất
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// 1. Đăng nhập bằng Email và Mật khẩu
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 2. Đăng ký tài khoản cầu thủ mới kèm Metadata (Họ tên, Vị trí, Chân thuận)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String position = 'Tiền đạo',
    String preferredFoot = 'Chân phải',
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'full_name': fullName.trim(),
          'position': position,
          'preferred_foot': preferredFoot,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 3. Gửi yêu cầu đặt lại mật khẩu qua Email (Quên mật khẩu)
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      rethrow;
    }
  }

  /// 4. Đổi mật khẩu mới cho người dùng đang đăng nhập
  Future<UserResponse> updatePassword({required String newPassword}) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword.trim()),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 5. Đăng xuất khỏi hệ thống
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
