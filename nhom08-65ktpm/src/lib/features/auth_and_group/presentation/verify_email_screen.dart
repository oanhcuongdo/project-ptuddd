import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../providers/auth_providers.dart';
import '../repository/auth_repository.dart';

/// Màn hình yêu cầu xác thực Email trước khi truy cập Trang chủ.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _checking = false;
  bool _resending = false;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkVerified() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final refreshed =
          await ref.read(authControllerProvider.notifier).reloadUser();
      if (!mounted) return;
      if (refreshed?.emailVerified == true) {
        context.go('/trips');
      } else {
        _showMessage(
          'Email vẫn chưa được xác thực. Hãy mở hộp thư (kể cả Spam) để bấm liên kết xác nhận.',
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resendEmail() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      final ok = await ref
          .read(authControllerProvider.notifier)
          .sendEmailVerification();
      if (!mounted) return;
      final state = ref.read(authControllerProvider);
      if (ok && !state.hasError) {
        _showMessage('Đã gửi lại email xác thực.');
      } else {
        _showMessage(state.error?.toString() ?? 'Không thể gửi lại email.');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực Email')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 16),
            AppInsetCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kiểm tra hộp thư của bạn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chúng tôi đã gửi liên kết xác thực tới:\n${user?.email ?? 'email của bạn'}.\nVui lòng xác thực email trước khi sử dụng Travel Buddy.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              key: const Key('verify_email_check_button'),
              label: _checking ? 'Đang kiểm tra...' : 'Tôi đã xác thực',
              icon: Icons.verified_outlined,
              onPressed: _checking ? null : _checkVerified,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _resending ? null : _resendEmail,
              icon: const Icon(Icons.refresh),
              label: Text(
                _resending ? 'Đang gửi...' : 'Gửi lại email xác thực',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
              child: const Text('Đăng xuất / Dùng tài khoản khác'),
            ),
          ],
        ),
      ),
    );
  }
}
