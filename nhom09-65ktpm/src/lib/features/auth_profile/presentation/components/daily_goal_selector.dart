import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class _DuolingoGoalOption {
  final int minutes;
  final String emoji;
  final String title;
  final String intensityLabel;

  const _DuolingoGoalOption({
    required this.minutes,
    required this.emoji,
    required this.title,
    required this.intensityLabel,
  });
}

/// Component chọn Mục tiêu kỷ luật hàng ngày phong cách Duolingo:
/// Danh sách thẻ ngang full-width có viền nổi 3D ở đáy (10p / 15p / 20p / 30p)
/// + 1 thẻ "Tùy chỉnh" mở ô nhập số phút bất kỳ mong muốn.
class DailyGoalSelector extends StatefulWidget {
  static const List<_DuolingoGoalOption> _options = [
    _DuolingoGoalOption(
      minutes: 10,
      emoji: '🌱',
      title: '10 phút / ngày',
      intensityLabel: 'Dễ dàng',
    ),
    _DuolingoGoalOption(
      minutes: 15,
      emoji: '🔥',
      title: '15 phút / ngày',
      intensityLabel: 'Thường xuyên',
    ),
    _DuolingoGoalOption(
      minutes: 20,
      emoji: '⚡',
      title: '20 phút / ngày',
      intensityLabel: 'Nghiêm túc',
    ),
    _DuolingoGoalOption(
      minutes: 30,
      emoji: '🚀',
      title: '30 phút / ngày',
      intensityLabel: 'Siêu cấp',
    ),
  ];

  final int? selectedMinutes;
  final ValueChanged<int?> onChanged;

  const DailyGoalSelector({
    super.key,
    required this.selectedMinutes,
    required this.onChanged,
  });

  @override
  State<DailyGoalSelector> createState() => _DailyGoalSelectorState();
}

class _DailyGoalSelectorState extends State<DailyGoalSelector> {
  late bool _isCustomMode;
  late final TextEditingController _customController;

  bool _isPreset(int minutes) =>
      DailyGoalSelector._options.any((opt) => opt.minutes == minutes);

  @override
  void initState() {
    super.initState();
    final initial = widget.selectedMinutes;
    _isCustomMode = initial != null && !_isPreset(initial);
    _customController = TextEditingController(
      text: _isCustomMode ? initial.toString() : '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _selectPreset(int minutes) {
    setState(() => _isCustomMode = false);
    widget.onChanged(minutes);
  }

  void _enableCustomMode() {
    setState(() => _isCustomMode = true);
    final parsed = int.tryParse(_customController.text.trim());
    if (parsed != null && parsed >= 5 && parsed <= 240) {
      widget.onChanged(parsed);
    } else {
      widget.onChanged(null);
    }
  }

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
                'Mục tiêu hàng ngày của bạn là gì?',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '🔥 Giữ Streak',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.streakOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...DailyGoalSelector._options.map((opt) {
          final isSelected =
              !_isCustomMode && opt.minutes == widget.selectedMinutes;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DuolingoGoalTile(
              emoji: opt.emoji,
              title: opt.title,
              intensityLabel: opt.intensityLabel,
              isSelected: isSelected,
              onTap: () => _selectPreset(opt.minutes),
            ),
          );
        }),
        _DuolingoGoalTile(
          emoji: '⏱️',
          title: 'Tùy chỉnh thời gian',
          intensityLabel: _isCustomMode && widget.selectedMinutes != null
              ? '${widget.selectedMinutes} phút / ngày'
              : 'Tự nhập',
          isSelected: _isCustomMode,
          onTap: _enableCustomMode,
        ),
        if (_isCustomMode) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _customController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Số phút mục tiêu mỗi ngày (5 – 240 phút)',
              hintText: 'Ví dụ: 45',
              suffixText: 'phút / ngày',
              prefixIcon: const Icon(Icons.timer_outlined),
              filled: true,
              fillColor: AppColors.surfaceWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value.trim());
              if (parsed != null && parsed >= 5 && parsed <= 240) {
                widget.onChanged(parsed);
              } else {
                widget.onChanged(null);
              }
            },
            validator: (value) {
              if (!_isCustomMode) return null;
              final parsed = int.tryParse((value ?? '').trim());
              if (parsed == null || parsed < 5 || parsed > 240) {
                return 'Nhập số phút từ 5 đến 240';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}

/// Một dòng lựa chọn mục tiêu phong cách Duolingo (full-width + viền đáy nổi 3D)
class _DuolingoGoalTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String intensityLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _DuolingoGoalTile({
    required this.emoji,
    required this.title,
    required this.intensityLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? AppColors.primary : const Color(0xFFE2E8F0);
    final bottomBorderColor =
        isSelected ? AppColors.primary : const Color(0xFFCBD5E1);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFFEEF2FF) : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.8 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: bottomBorderColor,
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              intensityLabel,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
