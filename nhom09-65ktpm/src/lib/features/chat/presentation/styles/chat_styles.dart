import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Bộ Style tông Xanh Ngọc (Teal / Emerald) dùng riêng cho khu vực Trò chuyện & Khám phá phòng học.
class ChatStyles {
  ChatStyles._();

  // Tông màu Xanh Ngọc chủ đạo (thay cho màu tím trên mockup)
  static const Color tealPrimary = Color(0xFF0D9488);
  static const Color tealDark = Color(0xFF0F766E);
  static const Color tealDeep = Color(0xFF115E59);
  static const Color tealLight = Color(0xFF14B8A6);
  static const Color tealSoftBg = Color(0xFFF0FDFA);
  static const Color tealPillBg = Color(0xFFCCFBF1);
  static const Color tealBorder = Color(0xFF99F6E4);

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

  static const BoxDecoration controlBoxDecoration = BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.all(Radius.circular(12)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFFE2E8F0), width: 1),
    ),
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 13.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle roomTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle roomDescription = TextStyle(
    fontSize: 12.8,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle metaText = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static const double cardRadius = AppSpacing.radiusLg;

  /// Danh sách định hướng kỹ năng dài hạn cho phòng học nhóm
  static const List<String> roomFocusOptions = [
    'Giao tiếp tự do',
    'IELTS / Chứng chỉ',
    'Phát âm',
    'Công sở',
    'Du lịch',
  ];

  /// Bộ ảnh bìa Gradient có sẵn cho người tạo phòng chọn nhanh
  static const List<({String key, String label, List<Color> colors})>
      coverPresets = [
    (
      key: 'preset:teal',
      label: 'Xanh ngọc',
      colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF2DD4BF)],
    ),
    (
      key: 'preset:ocean',
      label: 'Đại dương',
      colors: [Color(0xFF0C4A6E), Color(0xFF0284C7), Color(0xFF38BDF8)],
    ),
    (
      key: 'preset:forest',
      label: 'Rừng xanh',
      colors: [Color(0xFF14532D), Color(0xFF15803D), Color(0xFF4ADE80)],
    ),
    (
      key: 'preset:sunset',
      label: 'Hoàng hôn',
      colors: [Color(0xFF9A3412), Color(0xFFEA580C), Color(0xFFFBBF24)],
    ),
    (
      key: 'preset:midnight',
      label: 'Xanh đêm',
      colors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF0D9488)],
    ),
  ];

  static List<Color>? gradientForCoverKey(String? coverUrl) {
    if (coverUrl == null || !coverUrl.startsWith('preset:')) return null;
    for (final preset in coverPresets) {
      if (preset.key == coverUrl) return preset.colors;
    }
    return null;
  }
}
