import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/layouts/auth_layout.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/router/routes/auth_routes.dart';
import '../../../../core/components/app_button.dart';
import '../../../../core/components/app_error_text.dart';
import '../../../../core/components/app_text_field.dart';
import '../../../../core/theme/app_spacing.dart';
import '../components/auth_footer_link.dart';
import '../components/google_sign_in_button.dart';
import '../providers/auth_provider.dart';

/// Màn hình Đăng nhập — chỉ lắp ghép từ Layout + Components, không viết style trực tiếp
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (mounted && ok) {
      Navigator.of(context).pushReplacementNamed(AppRouter.initialRoute);
    }
  }

  Future<void> _handleGoogleLogin() async {
    final ok = await context.read<AuthProvider>().signInWithGoogle();
    if (mounted && ok) {
      Navigator.of(context).pushReplacementNamed(AppRouter.initialRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthLayout(
      title: 'Đăng nhập tài khoản',
      subtitle: 'Rèn luyện kỷ luật giao tiếp mỗi ngày cùng BuddyTalk',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _passwordController,
              label: 'Mật khẩu',
              obscureText: true,
              validator: (v) => (v == null || v.length < 6)
                  ? 'Mật khẩu tối thiểu 6 ký tự'
                  : null,
            ),
            AppErrorText(message: auth.errorMessage),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Đăng nhập',
              isLoading: auth.isLoading,
              onPressed: _handleEmailLogin,
            ),
            const SizedBox(height: AppSpacing.md),
            GoogleSignInButton(
              isLoading: auth.isLoading,
              onPressed: _handleGoogleLogin,
            ),
            AuthFooterLink(
              label: 'Chưa có tài khoản? Đăng ký ngay',
              onPressed: auth.isLoading
                  ? null
                  : () => Navigator.of(context).pushNamed(AuthRoutes.register),
            ),
          ],
        ),
      ),
    );
  }
}
