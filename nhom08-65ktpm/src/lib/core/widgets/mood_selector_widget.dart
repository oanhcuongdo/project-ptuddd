import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Item cảm xúc dùng trong [MoodSelectorWidget].
class MoodOption {
  const MoodOption({required this.emoji, required this.label});

  final String emoji;
  final String label;
}

/// Bộ chọn cảm xúc DailyYou dùng chung giữa nhật ký tiết kiệm và nộp biên lai.
class MoodSelectorWidget extends StatelessWidget {
  const MoodSelectorWidget({
    super.key,
    required this.selectedEmoji,
    required this.onSelected,
    this.options = defaultOptions,
  });

  static const defaultOptions = <MoodOption>[
    MoodOption(emoji: '🔥', label: 'Kỷ luật'),
    MoodOption(emoji: '😎', label: 'Nhẹ nhàng'),
    MoodOption(emoji: '🚀', label: 'Tăng tốc'),
    MoodOption(emoji: '💪', label: 'Kiên trì'),
    MoodOption(emoji: '🎉', label: 'Đạt mốc'),
  ];

  final String selectedEmoji;
  final ValueChanged<String> onSelected;
  final List<MoodOption> options;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final active = option.emoji == selectedEmoji;
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            HapticFeedback.lightImpact();
            onSelected(option.emoji);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.mintContainer : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppColors.mint : AppColors.outlineVariantSoft,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 5),
                Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.onMintContainer : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
