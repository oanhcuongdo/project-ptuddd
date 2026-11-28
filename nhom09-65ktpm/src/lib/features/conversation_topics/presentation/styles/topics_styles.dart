import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Cặp màu nền và màu chữ cho badge cấp độ CEFR (A1 - B2).
class TopicLevelStyle {
  final Color background;
  final Color foreground;
  final Color border;
  final String label;

  const TopicLevelStyle({
    required this.background,
    required this.foreground,
    required this.border,
    required this.label,
  });
}

/// Bộ Style tông Xanh Ngọc (Teal / Emerald) đồng bộ với BuddyTalk cho phân hệ Chủ đề hội thoại.
class TopicsStyles {
  TopicsStyles._();

  static const Color tealPrimary = Color(0xFF0D9488);
  static const Color tealDark = Color(0xFF0F766E);
  static const Color tealSoftBg = Color(0xFFF0FDFA);
  static const Color tealPillBg = Color(0xFFCCFBF1);
  static const Color tealBorder = Color(0xFF99F6E4);

  static const Color completedBg = Color(0xFFECFDF5);
  static const Color completedFg = Color(0xFF059669);
  static const Color completedBorder = Color(0xFFA7F3D0);

  static const double cardRadius = AppSpacing.radiusLg;

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE6EEF2), width: 1),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.045),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static const BoxDecoration bannerDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [tealDark, tealPrimary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const BoxDecoration filterSurfaceDecoration = BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFFE2E8F0), width: 1),
    ),
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: tealDark,
  );

  static const TextStyle cardDescription = TextStyle(
    fontSize: 12.8,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle metaText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  /// Trả về bảng màu trực quan riêng cho từng cấp độ CEFR (A1, A2, B1, B2).
  static TopicLevelStyle styleForLevel(String level) {
    switch (level.trim().toUpperCase()) {
      case 'A1':
        return const TopicLevelStyle(
          background: Color(0xFFECFDF5),
          foreground: Color(0xFF047857),
          border: Color(0xFFA7F3D0),
          label: 'A1 · Cơ bản',
        );
      case 'A2':
        return const TopicLevelStyle(
          background: Color(0xFFEFF6FF),
          foreground: Color(0xFF1D4ED8),
          border: Color(0xFFBFDBFE),
          label: 'A2 · Sơ cấp',
        );
      case 'B1':
        return const TopicLevelStyle(
          background: Color(0xFFFFF7ED),
          foreground: Color(0xFFC2410C),
          border: Color(0xFFFED7AA),
          label: 'B1 · Trung cấp',
        );
      case 'B2':
        return const TopicLevelStyle(
          background: Color(0xFFF5F3FF),
          foreground: Color(0xFF6D28D9),
          border: Color(0xFFDDD6FE),
          label: 'B2 · Trên trung cấp',
        );
      default:
        return const TopicLevelStyle(
          background: tealSoftBg,
          foreground: tealDark,
          border: tealBorder,
          label: 'Tất cả',
        );
    }
  }
}

