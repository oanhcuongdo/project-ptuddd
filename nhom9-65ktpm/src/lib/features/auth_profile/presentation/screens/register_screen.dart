import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/layouts/auth_layout.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/components/app_button.dart';
import '../../../../core/components/app_error_text.dart';
import '../../../../core/components/app_text_field.dart';
import '../../../../core/theme/app_spacing.dart';
import '../components/auth_footer_link.dart';
import '../providers/auth_provider.dart';

/// Màn hình Đăng ký — chỉ lắp ghép từ Layout + Components
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().registerWithEmail(
          displayName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (mounted && ok) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.initialRoute,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthLayout(
      title: 'Tạo tài khoản mới',
      subtitle: 'Bắt đầu hành trình vượt rào cản ngôn ngữ',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Tên hiển thị',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: AppSpacing.md),
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
              label: 'Đăng ký',
              isLoading: auth.isLoading,
              onPressed: _handleRegister,
            ),
            AuthFooterLink(
              label: 'Đã có tài khoản? Quay lại đăng nhập',
              onPressed:
                  auth.isLoading ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
