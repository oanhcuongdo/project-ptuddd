import 'dart:async';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// Bản giả của [AuthRepository] để **xem trước giao diện** mà không cần
/// cấu hình Firebase.
///
/// Chỉ dùng ở `lib/main_preview.dart` (demo UI/UX, issue #4); app thật dùng
/// `AuthRepositoryImpl` với Firebase. Mọi email/mật khẩu hợp lệ đều đăng nhập
/// được, sau 700 ms để thấy trạng thái chờ của nút.
class PreviewAuthRepository implements AuthRepository {
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return _emit(email: email);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _emit(email: email);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  Future<AppUser> _emit({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final user = AppUser(
      id: 'preview-user',
      email: email,
      displayName: 'Tài khoản xem trước',
    );
    _user = user;
    _controller.add(user);
    return user;
  }
}
