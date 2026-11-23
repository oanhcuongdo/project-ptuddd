import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Style & kích thước dùng riêng cho khung bố cục chính (MainLayout, Sidebar, Header)
class MainLayoutStyles {
  MainLayoutStyles._();

  /// Ngưỡng chuyển đổi giữa bố cục Chrome Desktop (Sidebar + Header + Outlet) và Mobile
  static const double desktopBreakpoint = 850;

  static const double sidebarWidthExpanded = 252;
  static const double sidebarWidthCollapsed = 76;
  static const double headerHeight = 68;

  static const Color sidebarBg = AppColors.surfaceWhite;
  static const Color headerBg = AppColors.surfaceWhite;
  static const Color outletBg = AppColors.scaffoldWebStart;
  static const Color navActiveBg = Color(0xFFEEF2FF);
  static const Color navHoverBg = Color(0xFFF8FAFC);

  static const BoxDecoration sidebarDecoration = BoxDecoration(
    color: sidebarBg,
    border: Border(
      right: BorderSide(color: AppColors.divider, width: 1),
    ),
  );

  static const BoxDecoration headerDecoration = BoxDecoration(
    color: headerBg,
    border: Border(
      bottom: BorderSide(color: AppColors.divider, width: 1),
    ),
  );

  static BoxDecoration brandLogoDecoration = BoxDecoration(
    gradient: const LinearGradient(
      colors: [AppColors.primary, AppColors.primaryLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.25),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static BoxDecoration streakPillDecoration = BoxDecoration(
    color: AppColors.streakBg,
    borderRadius: BorderRadius.circular(999),
    border: Border.all(
      color: AppColors.streakOrange.withValues(alpha: 0.25),
    ),
  );

  static BoxDecoration navItemDecoration({required bool isActive}) {
    return BoxDecoration(
      color: isActive ? navActiveBg : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    );
  }

  static const TextStyle brandName = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle brandSubtitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.8,
  );

  static TextStyle navLabel({required bool isActive}) => TextStyle(
        fontSize: 14,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
      );

  static const TextStyle headerTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
  );

  static const TextStyle userName = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle userMeta = TextStyle(
    fontSize: 11,
    color: AppColors.textMuted,
  );
}
