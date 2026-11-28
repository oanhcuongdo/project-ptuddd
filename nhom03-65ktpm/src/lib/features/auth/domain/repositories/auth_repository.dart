import '../entities/app_user.dart';

/// Hợp đồng xác thực của ứng dụng.
///
/// Tầng `domain` chỉ biết interface này; Firebase nằm ở `data/`. Nhờ vậy cubit,
/// widget test và các feature khác không phụ thuộc trực tiếp vào Firebase.
abstract interface class AuthRepository {
  /// Phát `null` khi chưa đăng nhập, phát [AppUser] khi đã đăng nhập.
  ///
  /// Stream này phát ngay phiên hiện tại (nếu có) nên app tự vào thẳng màn
  /// hình chính mà không cần người dùng đăng nhập lại.
  Stream<AppUser?> authStateChanges();

  /// Người dùng của phiên hiện tại nếu phiên đã được khôi phục.
  AppUser? get currentUser;

  /// Đăng nhập bằng email và mật khẩu.
  ///
  /// Ném `AuthFailure` (đã dịch sang tiếng Việt) khi thất bại.
  Future<AppUser> signIn({required String email, required String password});

  /// Tạo tài khoản mới bằng email và mật khẩu.
  ///
  /// Ném `AuthFailure` khi thất bại.
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  /// Đăng xuất khỏi thiết bị hiện tại.
  Future<void> signOut();
}
