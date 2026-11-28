import 'package:equatable/equatable.dart';

/// Người dùng đang đăng nhập — Dart thuần, không phụ thuộc Firebase.
///
/// `id` là Firebase UID; các bảng Supabase lưu UID này ở cột `user_id` kiểu
/// `text` (xem `docs/co_so_du_lieu.md`).
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.emailVerified = false,
  });

  final String id;
  final String email;
  final String? displayName;
  final bool emailVerified;

  String get displayLabel {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return email;
  }

  @override
  List<Object?> get props => <Object?>[id, email, displayName, emailVerified];
}
