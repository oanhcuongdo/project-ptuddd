import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/auth_profile/data/models/profile_model.dart';
import '../../../features/auth_profile/presentation/providers/auth_provider.dart';
import '../../../features/notifications/presentation/components/notification_bell_button.dart';
import '../styles/main_layout_styles.dart';
import 'nav_item.dart';

/// Component 2: Thanh Header nằm phía trên vùng Outlet bên phải.
/// Hiển thị tiêu đề trang theo NavLink đang chọn, Streak thật và tài khoản đang đăng nhập.
class MainHeader extends StatelessWidget {
  final MainNavItem currentItem;
  final bool showMenuButton;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenProfile;

  const MainHeader({
    super.key,
    required this.currentItem,
    this.showMenuButton = false,
    this.onOpenDrawer,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.currentProfile;

    return Container(
      height: MainLayoutStyles.headerHeight,
      padding: EdgeInsets.symmetric(
        horizontal: showMenuButton ? AppSpacing.md : AppSpacing.xl,
      ),
      decoration: MainLayoutStyles.headerDecoration,
      child: Row(
        children: [
          if (showMenuButton) ...[
            IconButton(
              onPressed: onOpenDrawer,
              tooltip: 'Mở menu',
              icon: const Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          if (currentItem.headerTitle.isNotEmpty)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentItem.headerTitle,
                    style: MainLayoutStyles.headerTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (currentItem.headerSubtitle.isNotEmpty)
                    Text(
                      currentItem.headerSubtitle,
                      style: MainLayoutStyles.headerSubtitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: AppSpacing.sm),
          if (profile != null) ...[
            _StreakStatusPill(streakCount: profile.streakCount),
            const SizedBox(width: AppSpacing.sm),
            const NotificationBellButton(),
            const SizedBox(width: AppSpacing.sm),
          ],
          _UserAccountMenu(
            profile: profile,
            onOpenProfile: onOpenProfile,
            onSignOut: auth.signOut,
          ),
        ],
      ),
    );
  }
}

class _StreakStatusPill extends StatelessWidget {
  final int streakCount;

  const _StreakStatusPill({required this.streakCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: MainLayoutStyles.streakPillDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: AppColors.streakOrange,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$streakCount ngày',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.streakOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAccountMenu extends StatelessWidget {
  final ProfileModel? profile;
  final VoidCallback? onOpenProfile;
  final Future<void> Function() onSignOut;

  const _UserAccountMenu({
    required this.profile,
    required this.onOpenProfile,
    required this.onSignOut,
  });

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'BT';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        (profile?.displayName.isNotEmpty ?? false) ? profile!.displayName : 'Tài khoản';
    final meta = profile == null
        ? 'Chưa đăng nhập'
        : '${profile!.targetLang.toUpperCase()} • ${profile!.proficiencyLevel}';
    final avatarUrl = profile?.avatarUrl;
    final hasNetworkAvatar = avatarUrl != null && avatarUrl.startsWith('http');

    return PopupMenuButton<String>(
      tooltip: 'Tài khoản',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      onSelected: (value) {
        if (value == 'profile') {
          onOpenProfile?.call();
        } else if (value == 'logout') {
          onSignOut();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18),
              SizedBox(width: AppSpacing.sm),
              Text('Hồ sơ cá nhân'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Đăng xuất',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderAvatar(
              avatarUrl: hasNetworkAvatar ? avatarUrl : null,
              initials: _initials(displayName),
            ),
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: MainLayoutStyles.userName,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    meta,
                    style: MainLayoutStyles.userMeta,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar Header có fallback chữ cái đầu sạch đẹp khi ảnh Google bị lỗi tải trên Web.
class _HeaderAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;

  const _HeaderAvatar({
    required this.avatarUrl,
    required this.initials,
  });

  Widget _buildInitials() {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: MainLayoutStyles.navActiveBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null) return _buildInitials();
    return ClipOval(
      child: Image.network(
        avatarUrl!,
        width: 34,
        height: 34,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitials(),
      ),
    );
  }
}
