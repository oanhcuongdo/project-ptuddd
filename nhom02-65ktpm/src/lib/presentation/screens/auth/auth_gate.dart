import 'package:flutter/material.dart';

import '../../../application/session_service.dart';
import '../../../core/di/injection_container.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

/// Cổng điều hướng theo trạng thái phiên:
/// chưa đăng nhập -> Đăng nhập; chưa xác nhận >= 18 tuổi -> Onboarding;
/// đủ điều kiện -> Ứng dụng chính.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<SessionService>();
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        return switch (session.status) {
          SessionStatus.loading => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          SessionStatus.signedOut => const LoginScreen(),
          SessionStatus.needsOnboarding => OnboardingScreen(key: ValueKey(session.uid)),
          // Key theo uid để đổi tài khoản thì toàn bộ state được tạo lại.
          SessionStatus.ready => MainShell(key: ValueKey(session.uid)),
        };
      },
    );
  }
}
