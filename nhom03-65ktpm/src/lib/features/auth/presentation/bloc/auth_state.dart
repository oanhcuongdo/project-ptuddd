import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';

/// Trạng thái phiên đăng nhập.
enum AuthStatus {
  /// Chưa biết Firebase đã khôi phục phiên hay chưa (đang mở app).
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final AppUser? user;

  /// Đang gửi yêu cầu đăng nhập/đăng ký/đăng xuất lên Firebase.
  final bool isSubmitting;

  /// Lỗi đã dịch sang tiếng Việt, hiển thị ngay trên form.
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isUnknown => status == AuthStatus.unknown;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    user,
    isSubmitting,
    errorMessage,
  ];
}
