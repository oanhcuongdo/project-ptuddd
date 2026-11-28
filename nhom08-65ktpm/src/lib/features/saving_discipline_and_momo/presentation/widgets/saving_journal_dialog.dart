import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_primary_button.dart';

/// Result returned from [SavingJournalDialog] when a user logs an emotion tag and note.
class SavingJournalDialogResult {
  final String emoji;
  final String note;

  const SavingJournalDialogResult({
    required this.emoji,
    required this.note,
  });
}

/// DailyYou-style Emotion Tags & Saving Journal Dialog for a streak check-in day.
class SavingJournalDialog extends StatefulWidget {
  const SavingJournalDialog({
    super.key,
    required this.date,
    this.initialEmoji,
    this.initialNote,
    this.alreadyCheckedIn = false,
  });

  final DateTime date;
  final String? initialEmoji;
  final String? initialNote;
  final bool alreadyCheckedIn;

  @override
  State<SavingJournalDialog> createState() => _SavingJournalDialogState();
}

class _SavingJournalDialogState extends State<SavingJournalDialog> {
  static const _emotionTags = [
    (emoji: '🔥', label: 'Kỷ luật'),
    (emoji: '😎', label: 'Nhẹ nhàng'),
    (emoji: '🚀', label: 'Tăng tốc'),
    (emoji: '💪', label: 'Kiên trì'),
    (emoji: '🎉', label: 'Đạt mốc'),
  ];

  static const _emotePalette = [
    '🥳', '☕', '🧋', '💰', '💎', '🎯', '✈️', '🏖️',
    '🍜', '🌟', '🙌', '❤️', '🤑', '🍀', '📈', '🏆',
  ];

  String _selectedEmoji = _emotionTags.first.emoji;
  bool _isCustomMode = false;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEmoji?.trim();
    final isPreset =
        initial == null || _emotionTags.any((t) => t.emoji == initial);
    _isCustomMode = !isPreset;
    _selectedEmoji = initial != null && initial.isNotEmpty
        ? initial
        : _emotionTags.first.emoji;
    _noteCtrl.text = widget.initialNote ?? '';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      SavingJournalDialogResult(
        emoji: _selectedEmoji,
        note: _noteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel =
        '${widget.date.day.toString().padLeft(2, '0')}/${widget.date.month.toString().padLeft(2, '0')}/${widget.date.year}';

    return Dialog(
      backgroundColor: AppColors.surfaceContainer,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(dayLabel),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.outlineVariantSoft),
              const SizedBox(height: 14),
              const Text(
                'CẢM XÚC HÔM NAY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              _buildEmotionGrid(),
              if (_isCustomMode) ...[
                const SizedBox(height: 12),
                _buildCustomEmoteGrid(),
              ],
              const SizedBox(height: 16),
              const Text(
                'GHI CHÚ TIẾT KIỆM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'VD: Nhịn 2 ly trà sữa góp quỹ chuyến đi!',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outlineVariantSoft),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outlineVariantSoft),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.mint, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AppPrimaryButton(
                label: widget.alreadyCheckedIn
                    ? 'Cập nhật nhật ký'
                    : 'Điểm danh & Lưu chuỗi',
                icon: widget.alreadyCheckedIn
                    ? Icons.check_rounded
                    : Icons.local_fire_department_rounded,
                backgroundColor: AppColors.mint,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String dayLabel) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.mintContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.mint.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: Text(_selectedEmoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.alreadyCheckedIn ? 'Cập nhật nhật ký' : 'Nhật ký tích góp',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dayLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.outlineVariantSoft),
              ),
            ),
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionGrid() {
    final items = <Widget>[
      ..._emotionTags.map((tag) {
        final isSelected = !_isCustomMode && _selectedEmoji == tag.emoji;
        return _EmotionTile(
          emoji: tag.emoji,
          label: tag.label,
          selected: isSelected,
          onTap: () => setState(() {
            _isCustomMode = false;
            _selectedEmoji = tag.emoji;
          }),
        );
      }),
      _EmotionTile(
        emoji: _isCustomMode && _emotePalette.contains(_selectedEmoji)
            ? _selectedEmoji
            : '✨',
        label: _isCustomMode && _emotePalette.contains(_selectedEmoji)
            ? 'Tùy chỉnh'
            : 'Khác',
        selected: _isCustomMode,
        onTap: () => setState(() {
          _isCustomMode = true;
          if (!_emotePalette.contains(_selectedEmoji)) {
            _selectedEmoji = _emotePalette.first;
          }
        }),
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: items[0]),
            const SizedBox(width: 8),
            Expanded(child: items[1]),
            const SizedBox(width: 8),
            Expanded(child: items[2]),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: items[3]),
            const SizedBox(width: 8),
            Expanded(child: items[4]),
            const SizedBox(width: 8),
            Expanded(child: items[5]),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomEmoteGrid() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariantSoft),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _emotePalette.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (context, index) {
          final emoji = _emotePalette[index];
          final active = _selectedEmoji == emoji;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _selectedEmoji = emoji),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.mintContainer : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active ? AppColors.mint : AppColors.outlineVariantSoft,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
          );
        },
      ),
    );
  }
}

class _EmotionTile extends StatelessWidget {
  const _EmotionTile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.mintContainer : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.mint : AppColors.outlineVariantSoft,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.onMintContainer : AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
