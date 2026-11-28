import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../providers/auth_providers.dart';
import '../repository/auth_repository.dart';

/// Màn hình Hồ sơ cá nhân — sửa thông tin, đổi mật khẩu (Email) và đăng xuất có xác nhận.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(authControllerProvider.notifier).signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user =
        ref.watch(authStateProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    final isEmailAccount = user?.isEmailPasswordUser ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          user?.initials ?? 'TB',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Thành viên Travel Buddy',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (user?.phoneNumber?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          user!.phoneNumber!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      AppStatusBadge(
                        label: isEmailAccount
                            ? 'Tài khoản Email'
                            : 'Google Sign-In',
                        tone: isEmailAccount
                            ? AppBadgeTone.primary
                            : AppBadgeTone.mint,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const AppSectionHeader(title: 'Tài khoản'),
          AppInsetCard(
            child: Column(
              children: [
                ListTile(
                  key: const Key('profile_edit_tile'),
                  leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  title: const Text('Chỉnh sửa thông tin'),
                  subtitle: const Text('Họ tên, số điện thoại, ảnh đại diện'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/edit'),
                ),
                if (isEmailAccount) ...[
                  const Divider(indent: 56),
                  ListTile(
                    key: const Key('profile_change_password_tile'),
                    leading: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    title: const Text('Đổi mật khẩu'),
                    subtitle: const Text('Cập nhật mật khẩu đăng nhập'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/change-password'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppInsetCard(
            child: ListTile(
              key: const Key('profile_logout_tile'),
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _confirmSignOut(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
