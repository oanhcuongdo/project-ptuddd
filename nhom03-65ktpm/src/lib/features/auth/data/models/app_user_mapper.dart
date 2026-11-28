import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';

/// Chuyển `User` của Firebase thành [AppUser] thuần Dart.
extension UserMapper on User {
  AppUser toAppUser() {
    return AppUser(
      id: uid,
      email: email ?? '',
      displayName: displayName,
      emailVerified: emailVerified,
    );
  }
}

/// Chuyển `User?` của Firebase; trả `null` khi chưa đăng nhập.
AppUser? mapUserOrNull(User? user) => user?.toAppUser();
