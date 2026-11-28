import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/tag_chip.dart';
import '../../domain/entities/note.dart';

/// Thẻ chủ đề theo mẫu đã duyệt, cũng hỗ trợ dạng danh sách.
class NoteCard extends StatelessWidget {
  const NoteCard({
    required this.note,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.compact = false,
    super.key,
  });

  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Đang được chọn để xuất tài liệu: viền `primary` + dấu tick.
  final bool selected;

  /// Dạng gọn cho lưới: giới hạn số dòng, một nhãn để không tràn ô.
  final bool compact;

  /// Tông màu ổn định theo id ghi chú — không đổi khi lọc/sắp xếp.
  int get _toneIndex {
    return note.id.codeUnits.fold<int>(0, (int sum, int c) => sum + c);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = AppNoteTones.of(context).toneAt(_toneIndex);
    final preview = note.content.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (compact) {
      return _buildTopicTile(context, preview);
    }
    final hasPreview = preview.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.container,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: selected
              ? scheme.primary
              : scheme.primary.withValues(alpha: 0),
          width: 2,
        ),
        boxShadow: AppShadows.soft(scheme.shadow),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        note.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: tone.onContainer,
                        ),
                      ),
                    ),
                    if (selected) ...<Widget>[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.check_circle, size: 20, color: scheme.primary),
                    ],
                  ],
                ),
                if (hasPreview) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    preview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tone.onContainer.withValues(alpha: 0.78),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Icon(
                      note.isDiary
                          ? Icons.event_note_rounded
                          : Icons.sticky_note_2_outlined,
                      size: 18,
                      color: tone.accent,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _formatUpdatedAt(note.updatedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tone.onContainer.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
                if (note.tags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: note.tags
                        .take(3)
                        .map((String tag) => TagChip(label: tag, tone: tone))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicTile(BuildContext context, String preview) {
    final theme = Theme.of(context);
    final topic = note.tags.isNotEmpty
        ? note.tags.first
        : note.isDiary
        ? 'Nhật ký'
        : 'Ghi chú';
    final (index, icon) = switch (topic.trim().toLowerCase()) {
      'toán' => (0, Icons.functions),
      'vật lý' => (1, Icons.bolt),
      'tiếng anh' => (2, Icons.translate),
      'sinh học' => (3, Icons.spa_outlined),
      'nhật ký' => (4, Icons.auto_stories_outlined),
      'lịch sử' => (5, Icons.history_edu_outlined),
      _ => (
        _toneIndex % NotesTopicColors.light.length,
        Icons.sticky_note_2_outlined,
      ),
    };
    final palette = theme.brightness == Brightness.dark
        ? NotesTopicColors.dark
        : NotesTopicColors.light;
    final ink = NotesTopicColors.foreground(index, theme.brightness);
    final date = note.updatedAt.toLocal();
    final titleStyle = theme.textTheme.titleSmall!.copyWith(color: ink);
    final previewStyle = theme.textTheme.bodySmall!.copyWith(color: ink);
    final scaler = MediaQuery.textScalerOf(context);
    double twoLines(TextStyle style) =>
        (scaler.scale(style.fontSize!) * (style.height ?? 1) * 2)
            .ceilToDouble();
    return Card.filled(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: palette[index],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NotesLayout.cardRadius),
        side: selected ? BorderSide(color: ink, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(NotesLayout.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      topic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(color: ink),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    selected ? Icons.check_circle : icon,
                    size: 19,
                    color: ink,
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: twoLines(titleStyle),
                child: Text(
                  note.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                  strutStyle: StrutStyle.fromTextStyle(
                    titleStyle,
                    forceStrutHeight: true,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: twoLines(previewStyle),
                child: Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: previewStyle,
                  strutStyle: StrutStyle.fromTextStyle(
                    previewStyle,
                    forceStrutHeight: true,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${_two(date.day)}/${_two(date.month)}',
                style: previewStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _two(int number) => number.toString().padLeft(2, '0');

  String _formatUpdatedAt(DateTime value) {
    final local = value.toLocal();
    return '${_two(local.day)}/${_two(local.month)} ${_two(local.hour)}:${_two(local.minute)}';
  }
}
