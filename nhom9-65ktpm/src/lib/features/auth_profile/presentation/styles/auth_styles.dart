import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// File style riêng cho phân hệ Auth (tương đương auth.module.css bên Web)
class AuthStyles {
  AuthStyles._();

  // Breakpoint Responsive: < 850px là Mobile (1 cột), >= 850px là Desktop/Chrome (2 cột kiểu Facebook)
  static const double desktopBreakpoint = 850;
  static const double maxMobileFormWidth = 420;
  static const double maxDesktopContainerWidth = 1020;
  static const double desktopCardWidth = 430;

  static const BoxDecoration webBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.scaffoldWebStart, AppColors.scaffoldWebEnd],
    ),
  );

  static BoxDecoration webCardDecoration(bool isDark) => BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.09),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      );

  static final BoxDecoration brandIconBox = BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF4F46E5),
        Color(0xFF5B5CE6),
        Color(0xFFD97757),
      ],
      stops: [0.0, 0.58, 1.0],
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static final BoxDecoration streakBadge = BoxDecoration(
    color: AppColors.streakBg,
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: Colors.white, width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static final BoxDecoration googleButtonBox = BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: AppColors.divider, width: 1.2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static final BoxDecoration primaryButtonShadow = BoxDecoration(
    borderRadius: BorderRadius.circular(999),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.32),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static const TextStyle brandDark = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle brandAccent = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    letterSpacing: -0.5,
  );

  static const TextStyle heroBrandDark = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
  );

  static const TextStyle heroBrandAccent = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    letterSpacing: -1.0,
  );

  static const TextStyle heroSubtitle = TextStyle(
    fontSize: 19,
    color: AppColors.textSecondary,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle tagline = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle linkAction = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}
