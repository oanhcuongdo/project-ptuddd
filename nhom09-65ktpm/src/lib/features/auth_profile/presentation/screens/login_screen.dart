import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/layouts/auth_layout.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/router/routes/auth_routes.dart';
import '../../../../core/components/app_button.dart';
import '../../../../core/components/app_error_text.dart';
import '../../../../core/components/app_text_field.dart';
import '../../../../core/theme/app_spacing.dart';
import '../components/auth_divider.dart';
import '../components/auth_footer_link.dart';
import '../components/google_sign_in_button.dart';
import '../providers/auth_provider.dart';
import '../styles/auth_styles.dart';

/// Màn hình Đăng nhập Responsive:
/// - Mobile (Android): 1 cột gọn đẹp
/// - Web (Chrome): 2 cột 
/// Thứ tự: Form Email/Mật khẩu + nút Đăng nhập ở trên, nút Google ở dưới.
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

  Future<void> _openRegister() async {
    final registeredEmail =
        await Navigator.of(context).pushNamed(AuthRoutes.register);
    if (!mounted) return;
    if (registeredEmail is String && registeredEmail.isNotEmpty) {
      _emailController.text = registeredEmail;
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF047857),
          content: Text(
            'Đăng ký thành công! Vui lòng đăng nhập để thiết lập hồ sơ cá nhân.',
          ),
        ),
      );
    }
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đặt lại mật khẩu đang được phát triển.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthLayout(
      cardTitle: 'Đăng nhập vào BuddyTalk',
      subtitle: 'Giữ vững kỷ luật – Vượt rào cản ngôn ngữ',
      footer: AuthFooterLink(
        prefixText: 'Chưa có tài khoản?',
        actionText: 'Đăng ký ngay',
        onPressed: auth.isLoading ? null : _openRegister,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _emailController,
              label: 'Email',
              hintText: 'tenban@buddytalk.vn',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _passwordController,
              label: 'Mật khẩu',
              hintText: 'Nhập mật khẩu',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: (v) => (v == null || v.length < 6)
                  ? 'Mật khẩu tối thiểu 6 ký tự'
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: auth.isLoading ? null : _handleForgotPassword,
                child: const Text(
                  'Quên mật khẩu?',
                  style: AuthStyles.linkAction,
                ),
              ),
            ),
            AppErrorText(message: auth.errorMessage),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Đăng nhập',
              trailingIcon: Icons.arrow_forward_rounded,
              isLoading: auth.isLoading,
              onPressed: _handleEmailLogin,
            ),
            const SizedBox(height: 20),
            const AuthDivider(text: 'hoặc tiếp tục với'),
            const SizedBox(height: 20),
            GoogleSignInButton(
              isLoading: auth.isLoading,
              onPressed: _handleGoogleLogin,
            ),
          ],
        ),
      ),
    );
  }
}
