import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../styles/main_layout_styles.dart';
import 'nav_item.dart';

/// Component 1: Thanh điều hướng bên trái (NavLink Sidebar) kiểu ứng dụng quản lý.
class MainNavSidebar extends StatelessWidget {
  final List<MainNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final VoidCallback? onSignOut;

  const MainNavSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed
        ? MainLayoutStyles.sidebarWidthCollapsed
        : MainLayoutStyles.sidebarWidthExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: MainLayoutStyles.sidebarDecoration,
      child: Column(
        children: [
          _buildBrandHeader(),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? AppSpacing.sm : AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              children: _buildGroupedNavLinks(),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          _buildFooterActions(),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return SizedBox(
      height: MainLayoutStyles.headerHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCollapsed ? AppSpacing.sm : AppSpacing.lg,
        ),
        child: isCollapsed
            ? Center(
                child: onToggleCollapse != null
                    ? IconButton(
                        onPressed: onToggleCollapse,
                        tooltip: 'Mở rộng menu',
                        icon: const Icon(
                          Icons.keyboard_double_arrow_right_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      )
                    : Container(
                        width: 36,
                        height: 36,
                        decoration: MainLayoutStyles.brandLogoDecoration,
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
              )
            : Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: MainLayoutStyles.brandLogoDecoration,
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: MainLayoutStyles.brandName,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Kỷ luật & Giao tiếp',
                          style: MainLayoutStyles.brandSubtitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onToggleCollapse != null)
                    IconButton(
                      onPressed: onToggleCollapse,
                      tooltip: 'Thu gọn menu',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.keyboard_double_arrow_left_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildGroupedNavLinks() {
    final widgets = <Widget>[];
    String? lastSection;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.section != lastSection) {
        if (lastSection != null) {
          widgets.add(const SizedBox(height: AppSpacing.md));
        }
        if (!isCollapsed) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                item.section.toUpperCase(),
                style: MainLayoutStyles.sectionHeader,
              ),
            ),
          );
        }
        lastSection = item.section;
      }

      widgets.add(
        _NavLinkTile(
          item: item,
          isActive: i == selectedIndex,
          isCollapsed: isCollapsed,
          onTap: () => onSelect(i),
        ),
      );
      widgets.add(const SizedBox(height: AppSpacing.xs));
    }

    return widgets;
  }

  Widget _buildFooterActions() {
    if (onSignOut == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(isCollapsed ? AppSpacing.sm : AppSpacing.md),
      child: _SidebarActionButton(
        icon: Icons.logout_rounded,
        label: 'Đăng xuất',
        isCollapsed: isCollapsed,
        color: AppColors.error,
        onTap: onSignOut!,
      ),
    );
  }
}

class _NavLinkTile extends StatelessWidget {
  final MainNavItem item;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _NavLinkTile({
    required this.item,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      hoverColor: MainLayoutStyles.navHoverBg,
      child: Container(
        height: 44,
        padding: EdgeInsets.symmetric(
          horizontal: isCollapsed ? 0 : AppSpacing.md,
        ),
        decoration: MainLayoutStyles.navItemDecoration(isActive: isActive),
        child: Row(
          mainAxisAlignment:
              isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              isActive ? item.selectedIcon : item.icon,
              size: 20,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.label,
                  style: MainLayoutStyles.navLabel(isActive: isActive),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ],
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(message: item.label, child: content);
    }
    return content;
  }
}

class _SidebarActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCollapsed;
  final Color color;
  final VoidCallback onTap;

  const _SidebarActionButton({
    required this.icon,
    required this.label,
    required this.isCollapsed,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      hoverColor: MainLayoutStyles.navHoverBg,
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 0 : AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment:
                isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 19, color: color),
              if (!isCollapsed) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(message: label, child: btn);
    }
    return btn;
  }
}
