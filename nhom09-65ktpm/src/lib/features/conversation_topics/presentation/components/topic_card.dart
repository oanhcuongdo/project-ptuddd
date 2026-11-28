import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/topic_model.dart';
import '../styles/topics_styles.dart';

/// Thẻ hiển thị một chủ đề hội thoại trong thư viện A1-B2.
class TopicCard extends StatelessWidget {
  final TopicModel topic;
  final bool isUpdating;
  final VoidCallback onTap;
  final VoidCallback onToggleCompleted;

  const TopicCard({
    super.key,
    required this.topic,
    required this.isUpdating,
    required this.onTap,
    required this.onToggleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final levelStyle = TopicsStyles.styleForLevel(topic.level);

    return Container(
      decoration: TopicsStyles.cardDecoration.copyWith(
        border: Border.all(
          color: topic.isCompleted
              ? TopicsStyles.completedBorder
              : const Color(0xFFE6EEF2),
          width: topic.isCompleted ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(levelStyle),
                const SizedBox(height: 12),
                Text(
                  topic.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TopicsStyles.cardTitle,
                ),
                if (topic.titleEn.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    topic.titleEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TopicsStyles.cardSubtitle,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  topic.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TopicsStyles.cardDescription,
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                _buildFooterRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(TopicLevelStyle levelStyle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: levelStyle.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: levelStyle.border),
          ),
          child: Text(
            topic.thumbnailIcon,
            style: const TextStyle(fontSize: 22),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPill(
                text: topic.level,
                bg: levelStyle.background,
                fg: levelStyle.foreground,
                border: levelStyle.border,
                isBold: true,
              ),
              _buildPill(
                text: topic.category,
                bg: const Color(0xFFF1F5F9),
                fg: AppColors.textSecondary,
                border: const Color(0xFFE2E8F0),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: topic.isCompleted
              ? 'Đã hoàn thành (bấm để bỏ đánh dấu)'
              : 'Đánh dấu đã hoàn thành',
          child: InkWell(
            onTap: isUpdating ? null : onToggleCompleted,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: TopicsStyles.tealPrimary,
                      ),
                    )
                  : Icon(
                      topic.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 22,
                      color: topic.isCompleted
                          ? TopicsStyles.completedFg
                          : AppColors.textMuted,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterRow() {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              _buildMetaItem(
                Icons.schedule_rounded,
                '${topic.estimatedMinutes} phút',
              ),
              _buildMetaItem(
                Icons.chat_bubble_outline_rounded,
                '${topic.starterCount} mở đầu',
              ),
              _buildMetaItem(
                Icons.forum_outlined,
                '${topic.dialogueCount} lượt thoại',
              ),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: TopicsStyles.tealPrimary,
        ),
      ],
    );
  }

  Widget _buildPill({
    required String text,
    required Color bg,
    required Color fg,
    required Color border,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: TopicsStyles.metaText),
      ],
    );
  }
}

