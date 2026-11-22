import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Kiểu chữ chuẩn dùng chung toàn ứng dụng (tương đương typography CSS)
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle brandTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle muted = TextStyle(
    fontSize: 14,
    color: AppColors.textMuted,
  );

  static const TextStyle error = TextStyle(
    fontSize: 13,
    color: AppColors.error,
  );
}
