import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soroban_kids_app/core/services/auth_service.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/presentation/screens/home_screen.dart';
import 'package:soroban_kids_app/injection_container.dart';
import 'auth_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: sl<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không thể kiểm tra trạng thái đăng nhập. '
                  'Hãy kiểm tra kết nối mạng rồi mở lại ứng dụng.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) return const AuthScreen();
        return HomeScreen(key: ValueKey(user.uid));
      },
    );
  }
}
