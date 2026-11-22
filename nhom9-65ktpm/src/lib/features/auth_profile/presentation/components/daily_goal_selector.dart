import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class _GoalOption {
  final int minutes;
  final String emoji;
  final String subtitle;

  const _GoalOption(this.minutes, this.emoji, this.subtitle);
}

/// Component chọn Mục tiêu kỷ luật hàng ngày (15p Khởi động / 20p Tiêu chuẩn / 30p Bứt phá)
class DailyGoalSelector extends StatelessWidget {
  static const List<_GoalOption> _options = [
    _GoalOption(15, '🔥', 'Khởi động'),
    _GoalOption(20, '🔥🔥', 'Tiêu chuẩn'),
    _GoalOption(30, '🚀', 'Bứt phá'),
  ];

  final int selectedMinutes;
  final ValueChanged<int> onChanged;

  const DailyGoalSelector({
    super.key,
    required this.selectedMinutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '🔥 Mục tiêu kỷ luật hàng ngày',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Giữ chuỗi Streak',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.streakOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: _options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final isSelected = opt.minutes == selectedMinutes;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: idx < 2 ? 10 : 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onChanged(opt.minutes),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.streakBg
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF97316)
                            : AppColors.divider,
                        width: isSelected ? 1.6 : 1.1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(opt.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 6),
                        Text(
                          '${opt.minutes} phút',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          opt.subtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFFEA580C)
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
