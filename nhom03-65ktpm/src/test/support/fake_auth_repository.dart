import 'dart:async';

import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/auth/domain/entities/app_user.dart';
import 'package:smart_note/features/auth/domain/repositories/auth_repository.dart';

/// Bản giả của [AuthRepository] để test không cần khởi tạo Firebase.
///
/// Hành vi giống Firebase ở điểm quan trọng: sau khi đăng nhập/đăng xuất,
/// stream phiên sẽ phát trạng thái mới.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser, this.signInFailure})
    : _currentUser = initialUser;

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  /// Nếu khác `null`, [signIn] sẽ ném lỗi này (dùng để test hiển thị lỗi).
  Failure? signInFailure;

  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final failure = signInFailure;
    if (failure != null) {
      throw failure;
    }
    return _signInAs(email);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _signInAs(email, displayName: displayName);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  AppUser _signInAs(String email, {String? displayName}) {
    final user = AppUser(
      id: 'uid-${email.trim()}',
      email: email.trim(),
      displayName: displayName,
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  Future<void> dispose() => _controller.close();
}
