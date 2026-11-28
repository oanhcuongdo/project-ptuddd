import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/level_colors.dart';
import '../../domain/enums.dart';

/// Chip hiển thị một mức độ, ví dụ "Độ ngọt: cao" (màu cam).
class LevelChip extends StatelessWidget {
  const LevelChip({
    super.key,
    required this.attribute,
    required this.level,
    this.compact = false,
  });

  final LevelAttribute attribute;
  final Level level;

  /// Bản thu gọn dùng trong thẻ bữa ăn.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = LevelColors.colorsOf(
      LevelColors.toneOf(attribute, level),
      Theme.of(context).brightness,
    );
    final text = '${AppStrings.attribute(attribute)}: ${AppStrings.level(attribute, level)}';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.foreground,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
