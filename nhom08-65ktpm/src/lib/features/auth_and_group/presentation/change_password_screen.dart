import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../providers/auth_providers.dart';

/// Màn hình Đổi mật khẩu (dành cho tài khoản Email/Password).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || next.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ mật khẩu hiện tại và mật khẩu mới.');
      return;
    }
    if (next.length < 6) {
      _showMessage('Mật khẩu mới cần tối thiểu 6 ký tự.');
      return;
    }
    if (next != confirm) {
      _showMessage('Mật khẩu xác nhận không khớp.');
      return;
    }

    final ok = await ref.read(authControllerProvider.notifier).changePassword(
          currentPassword: current,
          newPassword: next,
        );
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (!ok || state.hasError) {
      _showMessage(state.error?.toString() ?? 'Không thể đổi mật khẩu.');
      return;
    }
    _showMessage('Đổi mật khẩu thành công!');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppInsetCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _currentCtrl,
                  enabled: !isLoading,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newCtrl,
                  enabled: !isLoading,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới (>= 6 ký tự)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmCtrl,
                  enabled: !isLoading,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nhập lại mật khẩu mới',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: isLoading ? 'Đang cập nhật...' : 'Cập nhật mật khẩu',
            onPressed: isLoading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
