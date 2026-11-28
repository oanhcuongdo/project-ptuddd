import 'package:flutter/material.dart';

/// Design System Bảng màu chuẩn Material 3 cho GoodDeeds Fund
/// Định hướng: Ấm áp, Đáng tin cậy, Minh bạch & Truyền cảm hứng
class AppColors {
  // Brand Colors
  /// Primary: Xanh ngọc / Teal - Biểu tượng sự tin cậy, chính trực và phát triển bền vững
  static const Color primary = Color(0xFF0F9D8A);
  static const Color primaryDark = Color(0xFF0A7B6C);
  static const Color primaryLight = Color(0xFFE6F5F3);

  /// Secondary / Accent: Cam ấm - Biểu tượng lòng nhân ái, nhiệt huyết tuổi trẻ, dùng cho CTA & FAB
  static const Color accent = Color(0xFFFF8A3D);
  static const Color accentLight = Color(0xFFFFF3EB);
  static const Color secondary = Color(0xFFFF8A3D);

  // Status & Feedback Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0288D1);

  // Background & Surface (Light Mode)
  static const Color backgroundLight = Color(0xFFF7FAF9);
  static const Color cardLight = Colors.white;
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Background & Surface (Dark Mode)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF0F9D8A), Color(0xFF096E60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF8A3D), Color(0xFFE56B1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
