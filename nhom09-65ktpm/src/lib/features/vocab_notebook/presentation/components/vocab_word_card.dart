import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/vocab_entry_model.dart';
import '../styles/vocab_styles.dart';

/// Thẻ hiển thị một mục từ vựng trong Sổ tay cá nhân:
/// Từ gốc, badge cặp ngôn ngữ, nghĩa dịch, câu ví dụ từ chat và các nút Đã thuộc / Sửa / Xóa.
class VocabWordCard extends StatelessWidget {
  final VocabEntryModel entry;
  final VoidCallback onToggleMastered;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VocabWordCard({
    super.key,
    required this.entry,
    required this.onToggleMastered,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final langColors = VocabStyles.badgeColorsForLang(entry.sourceLang);
    final isMastered = entry.isMastered;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: isMastered
          ? VocabStyles.masteredCardDecoration
          : VocabStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: langColors.bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: langColors.border),
                ),
                child: Text(
                  entry.languagePairLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: langColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isMastered
                      ? VocabStyles.masteredBg
                      : VocabStyles.learningBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isMastered
                        ? VocabStyles.masteredBorder
                        : VocabStyles.learningBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMastered
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      size: 12,
                      color: isMastered
                          ? VocabStyles.masteredText
                          : VocabStyles.learningText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isMastered ? 'Đã thuộc' : 'Đang học',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isMastered
                            ? VocabStyles.masteredText
                            : VocabStyles.learningText,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(_formatDate(entry.createdAt), style: VocabStyles.metaText),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(entry.word, style: VocabStyles.wordTitle),
          const SizedBox(height: 4),
          SelectableText(
            entry.translatedMeaning,
            style: VocabStyles.meaningText,
          ),
          if (entry.hasExample) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: VocabStyles.exampleQuoteDecoration,
              child: Text(
                '"${entry.exampleSentence}"',
                style: VocabStyles.exampleText,
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 6),
          Row(
            children: [
              InkWell(
                onTap: onToggleMastered,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMastered
                            ? Icons.replay_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 16,
                        color: isMastered
                            ? AppColors.textSecondary
                            : VocabStyles.masteredText,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isMastered ? 'Ôn lại' : 'Đánh dấu đã thuộc',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isMastered
                              ? AppColors.textSecondary
                              : VocabStyles.masteredText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Chỉnh sửa từ vựng',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Xóa khỏi Sổ tay',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
