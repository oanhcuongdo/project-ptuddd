import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Giữ trạng thái phiên đăng nhập cho toàn app.
///
/// Widget chỉ đọc [AuthState]; mọi thao tác với Firebase đi qua repository.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;
  StreamSubscription<AppUser?>? _subscription;

  /// Bắt đầu lắng nghe phiên đăng nhập; gọi một lần sau khi app khởi động.
  ///
  /// Firebase phát ngay phiên đã lưu trên máy (nếu có), nên người dùng đã đăng
  /// nhập sẽ vào thẳng màn hình chính.
  void start() {
    _subscription ??= _repository.authStateChanges().listen(
      _onUserChanged,
      onError: (Object error) {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            isSubmitting: false,
            clearUser: true,
            errorMessage: error is Failure ? error.message : null,
          ),
        );
      },
    );
  }

  void _onUserChanged(AppUser? user) {
    emit(
      state.copyWith(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user,
        clearUser: user == null,
        isSubmitting: false,
        clearError: true,
      ),
    );
  }

  /// Đăng nhập; trả `true` khi Firebase chấp nhận thông tin.
  Future<bool> signIn({required String email, required String password}) {
    return _submit(() => _repository.signIn(email: email, password: password));
  }

  /// Đăng ký tài khoản mới; trả `true` khi tạo thành công.
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _submit(
      () => _repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> signOut() async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repository.signOut();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isSubmitting: false,
          clearUser: true,
        ),
      );
    } on Failure catch (failure) {
      emit(state.copyWith(isSubmitting: false, errorMessage: failure.message));
    }
  }

  /// Xoá thông báo lỗi đang hiển thị (khi người dùng sửa lại form).
  void clearError() {
    if (state.errorMessage != null) {
      emit(state.copyWith(clearError: true));
    }
  }

  Future<bool> _submit(Future<AppUser> Function() action) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final user = await action();
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isSubmitting: false,
          clearError: true,
        ),
      );
      return true;
    } on Failure catch (failure) {
      emit(state.copyWith(isSubmitting: false, errorMessage: failure.message));
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
