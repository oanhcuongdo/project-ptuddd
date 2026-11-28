import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../helpers/chat_translate_helper.dart';
import '../styles/chat_styles.dart';

/// Dữ liệu trả về khi người dùng xác nhận sửa lỗi câu trong [InlineCorrectionDialog].
class InlineCorrectionDraft {
  final String originalText;
  final String correctedText;
  final String note;

  const InlineCorrectionDraft({
    required this.originalText,
    required this.correctedText,
    required this.note,
  });
}

/// Thẻ hiển thị tin nhắn Sửa lỗi câu trực tiếp (Inline Correction):
/// Gạch ngang câu sai màu đỏ và hiển thị câu chuẩn màu xanh nổi bật.
class InlineCorrectionBubble extends StatelessWidget {
  final InlineCorrectionData data;
  final bool isMine;

  const InlineCorrectionBubble({
    super.key,
    required this.data,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final badgeBg = isMine
        ? Colors.white.withValues(alpha: 0.18)
        : ChatStyles.tealSoftBg;
    final badgeText = isMine ? Colors.white : ChatStyles.tealDark;

    final strikeColor = isMine
        ? const Color(0xFFFECACA)
        : const Color(0xFFDC2626);
    final fixedColor = isMine
        ? const Color(0xFFD1FAE5)
        : const Color(0xFF047857);
    final noteColor = isMine
        ? Colors.white.withValues(alpha: 0.88)
        : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.spellcheck_rounded, size: 12, color: badgeText),
              const SizedBox(width: 4),
              Text(
                'Gợi ý sửa câu',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: badgeText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, size: 14, color: strikeColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                data.originalText,
                style: TextStyle(
                  fontSize: 12.8,
                  color: strikeColor,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: strikeColor,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 14, color: fixedColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                data.correctedText,
                style: TextStyle(
                  fontSize: 13.8,
                  fontWeight: FontWeight.w700,
                  color: isMine ? Colors.white : fixedColor,
                  height: 1.38,
                ),
              ),
            ),
          ],
        ),
        if (data.hasNote) ...[
          const SizedBox(height: 5),
          Text(
            'Ghi chú: ${data.note}',
            style: TextStyle(
              fontSize: 11.8,
              fontStyle: FontStyle.italic,
              color: noteColor,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

/// Hộp thoại cho phép sửa câu viết sai của bạn học và gửi lại dưới dạng [InlineCorrectionBubble].
class InlineCorrectionDialog extends StatefulWidget {
  final String originalText;

  const InlineCorrectionDialog({
    super.key,
    required this.originalText,
  });

  static Future<InlineCorrectionDraft?> show(
    BuildContext context, {
    required String originalText,
  }) {
    return showDialog<InlineCorrectionDraft>(
      context: context,
      builder: (_) => InlineCorrectionDialog(originalText: originalText),
    );
  }

  @override
  State<InlineCorrectionDialog> createState() => _InlineCorrectionDialogState();
}

class _InlineCorrectionDialogState extends State<InlineCorrectionDialog> {
  late final TextEditingController _correctedController;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _correctedController = TextEditingController(
      text: ChatTranslateHelper.plainTextForTranslation(widget.originalText),
    );
  }

  @override
  void dispose() {
    _correctedController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final corrected = _correctedController.text.trim();
    if (corrected.isEmpty) return;
    Navigator.of(context).pop(
      InlineCorrectionDraft(
        originalText:
            ChatTranslateHelper.plainTextForTranslation(widget.originalText),
        correctedText: corrected,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanOriginal =
        ChatTranslateHelper.plainTextForTranslation(widget.originalText);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ChatStyles.tealSoftBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ChatStyles.tealBorder),
                    ),
                    child: const Icon(
                      Icons.spellcheck_rounded,
                      color: ChatStyles.tealDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sửa lỗi câu cho bạn học',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Giúp đối tác diễn đạt tự nhiên và đúng ngữ pháp hơn',
                          style: ChatStyles.metaText,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Câu gốc của bạn học:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  cleanOriginal,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Câu gợi ý sửa chuẩn *',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF047857),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _correctedController,
                maxLines: 3,
                minLines: 1,
                cursorColor: ChatStyles.tealPrimary,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 13.8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập lại câu đúng ngữ pháp...',
                  filled: true,
                  fillColor: const Color(0xFFECFDF5),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFA7F3D0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFA7F3D0)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Giải thích ngắn (tùy chọn)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLines: 2,
                minLines: 1,
                cursorColor: ChatStyles.tealPrimary,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Dùng quá khứ đơn "went" thay vì "go".',
                  hintStyle: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: _correctedController.text.trim().isEmpty
                        ? null
                        : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: ChatStyles.tealPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text(
                      'Gửi gợi ý sửa',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
