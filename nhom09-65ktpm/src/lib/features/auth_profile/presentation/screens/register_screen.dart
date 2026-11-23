import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/layouts/auth_layout.dart';
import '../../../../core/components/app_button.dart';
import '../../../../core/components/app_error_text.dart';
import '../../../../core/components/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../components/auth_footer_link.dart';
import '../components/password_strength_bar.dart';
import '../components/terms_checkbox.dart';
import '../providers/auth_provider.dart';

/// Màn hình Đăng ký tài khoản gọn nhẹ (chỉ gồm Email, Mật khẩu & Xác nhận mật khẩu).
/// Đăng ký thành công sẽ quay về trang Đăng nhập để người dùng đăng nhập và thiết lập hồ sơ.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptedTerms = true;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() {
        _localError = 'Vui lòng đồng ý với Điều khoản sử dụng để tiếp tục.';
      });
      return;
    }

    setState(() => _localError = null);

    final email = _emailController.text.trim();
    final ok = await context.read<AuthProvider>().registerWithEmail(
          email: email,
          password: _passwordController.text,
        );

    if (mounted && ok) {
      Navigator.of(context).pop(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthLayout(
      subtitle: 'Giữ vững kỷ luật – Vượt rào cản ngôn ngữ',
      showMobileBrandHeader: false,
      footer: AuthFooterLink(
        prefixText: 'Đã có tài khoản?',
        actionText: 'Quay lại đăng nhập',
        onPressed: auth.isLoading ? null : () => Navigator.of(context).pop(),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed:
                      auth.isLoading ? null : () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Tạo tài khoản BuddyTalk',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '🔥 Tạo nhanh bằng Email — sau khi đăng nhập bạn sẽ thiết lập hồ sơ cá nhân.',
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              hintText: 'tenban@buddytalk.vn',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
            ),
            const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: 10),
            PasswordStrengthBar(password: _passwordController.text),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _confirmPasswordController,
              label: 'Xác nhận mật khẩu',
              hintText: 'Nhập lại mật khẩu',
              prefixIcon: Icons.verified_user_outlined,
              obscureText: true,
              validator: (v) => (v != _passwordController.text)
                  ? 'Mật khẩu xác nhận không khớp'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TermsCheckbox(
              value: _acceptedTerms,
              onChanged: (v) => setState(() {
                _acceptedTerms = v;
                if (v) _localError = null;
              }),
            ),
            AppErrorText(message: _localError ?? auth.errorMessage),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Đăng ký tài khoản',
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
