import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../providers/auth_providers.dart';

/// Màn hình Đăng ký tài khoản Email/Password toàn trang.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _showMessage('Vui lòng điền đầy đủ họ tên, email và mật khẩu.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _showMessage('Địa chỉ email không đúng định dạng.');
      return;
    }
    if (pass.length < 6) {
      _showMessage('Mật khẩu cần tối thiểu 6 ký tự.');
      return;
    }
    if (pass != confirm) {
      _showMessage('Mật khẩu xác nhận không khớp.');
      return;
    }

    final user = await ref.read(authControllerProvider.notifier).registerWithEmail(
          email: email,
          password: pass,
          displayName: name,
        );
    if (!mounted) return;

    final state = ref.read(authControllerProvider);
    if (state.hasError || user == null) {
      _showMessage(state.error?.toString() ?? 'Đăng ký thất bại.');
      return;
    }

    if (user.emailVerified) {
      context.go('/trips');
    } else {
      context.go('/verify-email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Tạo tài khoản Travel Buddy để đồng bộ kế hoạch, quỹ nhóm và chi tiêu cùng bạn bè.',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            AppInsetCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    key: const Key('register_name_field'),
                    controller: _nameCtrl,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('register_email_field'),
                    controller: _emailCtrl,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'tenban@e.tlu.edu.vn',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('register_password_field'),
                    controller: _passwordCtrl,
                    enabled: !isLoading,
                    obscureText: _obscurePass,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu (>= 6 ký tự)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('register_confirm_field'),
                    controller: _confirmCtrl,
                    enabled: !isLoading,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Nhập lại mật khẩu',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              key: const Key('register_submit_button'),
              label: isLoading ? 'Đang tạo tài khoản...' : 'Tạo tài khoản',
              onPressed: isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
