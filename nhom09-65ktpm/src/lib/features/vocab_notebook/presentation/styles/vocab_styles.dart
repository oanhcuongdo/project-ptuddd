import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Bộ Style chuẩn Material 3 (tông Xanh Ngọc Teal) cho Phân hệ Sổ tay Từ vựng (`vocab_notebook`).
/// Đồng bộ thiết kế với `ChatStyles` và `AppColors` của toàn ứng dụng BuddyTalk.
class VocabStyles {
  VocabStyles._();

  // Bảng màu Xanh Ngọc chủ đạo
  static const Color tealPrimary = Color(0xFF0D9488);
  static const Color tealDark = Color(0xFF0F766E);
  static const Color tealDeep = Color(0xFF115E59);
  static const Color tealLight = Color(0xFF14B8A6);
  static const Color tealSoftBg = Color(0xFFF0FDFA);
  static const Color tealPillBg = Color(0xFFCCFBF1);
  static const Color tealBorder = Color(0xFF99F6E4);

  // Màu trạng thái học từ
  static const Color masteredBg = Color(0xFFECFDF5);
  static const Color masteredText = Color(0xFF047857);
  static const Color masteredBorder = Color(0xFFA7F3D0);

  static const Color learningBg = Color(0xFFFFF7ED);
  static const Color learningText = Color(0xFFC2410C);
  static const Color learningBorder = Color(0xFFFED7AA);

  static const Color cardBorder = Color(0xFFE2ECF0);

  /// Bảng màu badge phân biệt theo ngôn ngữ nguồn (`en`, `zh-cn`, `vi`)
  static ({Color bg, Color text, Color border}) badgeColorsForLang(
    String rawCode,
  ) {
    final normalized = rawCode.trim().toLowerCase().replaceAll('_', '-');
    if (normalized.startsWith('zh')) {
      return (
        bg: const Color(0xFFFEF2F2),
        text: const Color(0xFFB91C1C),
        border: const Color(0xFFFECACA),
      );
    }
    if (normalized.startsWith('en')) {
      return (
        bg: const Color(0xFFEEF2FF),
        text: const Color(0xFF4338CA),
        border: const Color(0xFFC7D2FE),
      );
    }
    return (
      bg: tealSoftBg,
      text: tealDark,
      border: tealBorder,
    );
  }

  /// Thẻ thống kê đầu trang Sổ tay (Hero Banner Gradient Teal)
  static BoxDecoration get statsHeroDecoration => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tealDeep, tealDark, tealPrimary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: tealDark.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );

  /// Khung thẻ trắng chuẩn Material 3 cho thẻ từ vựng và hộp tra cứu
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      );

  /// Thẻ từ vựng đã đánh dấu thuộc
  static BoxDecoration get masteredCardDecoration => BoxDecoration(
        color: const Color(0xFFFAFDFC),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: masteredBorder),
        boxShadow: [
          BoxShadow(
            color: masteredText.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Khung trích dẫn câu ví dụ lấy từ phòng chat
  static BoxDecoration get exampleQuoteDecoration => BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: tealLight, width: 3),
        ),
      );

  /// Mặt trước thẻ Flashcard
  static BoxDecoration get flashcardFrontDecoration => BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tealBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: tealDark.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      );

  /// Mặt sau thẻ Flashcard (hiện nghĩa tiếng Việt)
  static BoxDecoration get flashcardBackDecoration => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tealSoftBg, Color(0xFFE6FFFA)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tealPrimary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: tealPrimary.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      );

  static InputDecoration inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 19, color: AppColors.textMuted)
          : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: tealPrimary, width: 1.5),
      ),
    );
  }

  // Kiểu chữ chuẩn
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle wordTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle meaningText = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: tealDark,
    height: 1.35,
  );

  static const TextStyle exampleText = TextStyle(
    fontSize: 12.8,
    fontStyle: FontStyle.italic,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle metaText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}
