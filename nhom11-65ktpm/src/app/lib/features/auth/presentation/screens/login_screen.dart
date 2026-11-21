import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassScaffold(
      appBar: const GlassAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EntranceAnimation(
                child: CookieIcon(icon: Icons.lock_outline, color: AppColors.primary, size: 96, lobes: 12),
              ),
              const SizedBox(height: 20),
              EntranceAnimation(
                index: 1,
                child: Text('Đăng Nhập', style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: 4),
              EntranceAnimation(
                index: 2,
                child: Text(
                  'Tiếp tục hành trình học tiếng Trung',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 28),
              EntranceAnimation(
                index: 3,
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const TextField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                      ),
                      const SizedBox(height: 14),
                      const TextField(
                        obscureText: true,
                        decoration: InputDecoration(labelText: 'Mật khẩu', prefixIcon: Icon(Icons.key_outlined)),
                      ),
                      const SizedBox(height: 20),
                      GlassButton(label: 'Đăng Nhập', prominent: true, expand: true, onPressed: () {}),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
