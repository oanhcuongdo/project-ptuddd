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

/// Màn hình Đăng ký đồng bộ giao diện Responsive (Mobile 1 cột & Chrome 2 cột)
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
      cardTitle: 'Tạo tài khoản mới',
      subtitle: 'Giữ vững kỷ luật – Vượt rào cản ngôn ngữ',
      footer: AuthFooterLink(
        prefixText: 'Đã có tài khoản?',
        actionText: 'Đăng nhập ngay',
        onPressed: auth.isLoading ? null : () => Navigator.of(context).pop(),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Tên hiển thị',
              hintText: 'Nguyễn Văn A',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
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
              hintText: 'Tối thiểu 6 ký tự',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: (v) => (v == null || v.length < 6)
                  ? 'Mật khẩu tối thiểu 6 ký tự'
                  : null,
            ),
            AppErrorText(message: auth.errorMessage),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Đăng ký',
              trailingIcon: Icons.arrow_forward_rounded,
              isLoading: auth.isLoading,
              onPressed: _handleRegister,
            ),
          ],
        ),
      ),
    );
  }
}
