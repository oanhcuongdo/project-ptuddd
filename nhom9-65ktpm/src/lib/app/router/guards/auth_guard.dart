import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/auth_profile/presentation/providers/auth_provider.dart';
import '../../../features/auth_profile/presentation/screens/login_screen.dart';

/// Cổng bảo vệ đường dẫn.
/// - Đang khôi phục phiên từ Firebase + Supabase: hiển thị màn chờ ngắn (không chớp màn Login).
/// - Chưa đăng nhập: chặn và hiển thị LoginScreen.
/// - Đã đăng nhập: cho phép vào màn hình con [child].
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isInitializing) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldWebStart,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: AppSpacing.md),
              Text(
                'Đang khôi phục phiên đăng nhập...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }
    return child;
  }
}
