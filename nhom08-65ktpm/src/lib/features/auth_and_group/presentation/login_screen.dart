import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../providers/auth_providers.dart';

/// Màn hình Đăng nhập — kết nối Firebase Auth (Email/Password & Google Sign-In).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ Email và Mật khẩu.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _showMessage('Địa chỉ email không đúng định dạng.');
      return;
    }

    final user = await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(email: email, password: password);
    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState.hasError) {
      _showMessage(authState.error.toString());
      return;
    }
    if (user != null) {
      context.go(user.emailVerified ? '/trips' : '/verify-email');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final user =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState.hasError) {
      _showMessage(authState.error.toString());
      return;
    }
    if (user != null) {
      context.go('/trips');
    }
  }

  void _openForgotPassword() {
    final email = _emailController.text.trim();
    context.push(
      email.isEmpty
          ? '/forgot-password'
          : '/forgot-password?email=${Uri.encodeComponent(email)}',
    );
  }

  void _openRegisterPage() {
    context.push('/register');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.explore,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Travel Buddy',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Checklist chuẩn bị • Quỹ nhóm MoMo • Ngân sách',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    // Form
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppInsetCard(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 80,
                                      child: Text(
                                        'Email',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        key: const Key('login_email_field'),
                                        controller: _emailController,
                                        enabled: !isLoading,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          hintText: 'tenban@e.tlu.edu.vn',
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(indent: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 80,
                                      child: Text(
                                        'Mật khẩu',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        key: const Key('login_password_field'),
                                        controller: _passwordController,
                                        enabled: !isLoading,
                                        obscureText: _obscurePassword,
                                        decoration: const InputDecoration(
                                          hintText: 'Nhập mật khẩu',
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading ? null : _openForgotPassword,
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                color: AppColors.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppPrimaryButton(
                          key: const Key('login_submit_button'),
                          label: isLoading ? 'Đang đăng nhập...' : 'Đăng nhập',
                          onPressed: isLoading ? null : _handleLogin,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: isLoading ? null : _handleGoogleSignIn,
                            icon: const Icon(
                              Icons.g_mobiledata,
                              size: 28,
                              color: AppColors.primary,
                            ),
                            label: const Text(
                              'Tiếp tục với Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.surfaceContainer,
                              side: const BorderSide(
                                color: AppColors.outlineVariantSoft,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Footer
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chưa có tài khoản? ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          GestureDetector(
                            onTap: isLoading ? null : _openRegisterPage,
                            child: const Text(
                              'Đăng ký ngay',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
