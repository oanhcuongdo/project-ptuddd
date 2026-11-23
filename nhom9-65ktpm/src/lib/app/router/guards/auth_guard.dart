import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/auth_profile/presentation/providers/auth_provider.dart';
import '../../../features/auth_profile/presentation/screens/login_screen.dart';
import '../../../features/auth_profile/presentation/screens/profile_onboarding_screen.dart';

/// Cổng bảo vệ đường dẫn & điều phối luồng Onboarding kiểu Duolingo:
/// 1. Đang khôi phục phiên: hiển thị màn chờ ngắn (không chớp màn Login).
/// 2. Chưa đăng nhập: hiển thị LoginScreen.
/// 3. Đã đăng nhập (Email hoặc Google) nhưng chưa setup hồ sơ: hiển thị ProfileOnboardingScreen.
/// 4. Đã hoàn tất thiết lập hồ sơ: vào thẳng màn hình chính [child].
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

    if (auth.needsOnboarding) {
      return const ProfileOnboardingScreen();
    }

    return child;
  }
}
