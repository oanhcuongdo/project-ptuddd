import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth_profile/presentation/providers/auth_provider.dart';
import '../../../features/auth_profile/presentation/screens/login_screen.dart';

/// Cổng bảo vệ đường dẫn.
/// - Chưa đăng nhập: chặn và hiển thị LoginScreen.
/// - Đã đăng nhập: cho phép vào màn hình con [child].
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    if (!isAuthenticated) {
      return const LoginScreen();
    }
    return child;
  }
}
