import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../chat_online/models/translation_result.dart';
import '../styles/chat_styles.dart';

/// Khung hiển thị bản dịch tức thì gọn nhẹ ngay bên dưới bong bóng tin nhắn trong Phòng Chat.
/// Kèm nút "Tách từ & Lưu" để người học chọn từ đơn lưu vào Sổ tay Từ vựng.
class MessageTranslationFooter extends StatelessWidget {
  final TranslationResult? result;
  final bool isTranslating;
  final VoidCallback? onPickWords;
  final VoidCallback? onRetry;
  final VoidCallback? onHide;

  const MessageTranslationFooter({
    super.key,
    this.result,
    this.isTranslating = false,
    this.onPickWords,
    this.onRetry,
    this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    if (isTranslating) {
      return Container(
        margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: ChatStyles.tealSoftBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ChatStyles.tealBorder),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ChatStyles.tealPrimary,
              ),
            ),
            SizedBox(width: 7),
            Text(
              'Đang dịch câu chat...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ChatStyles.tealDark,
              ),
            ),
          ],
        ),
      );
    }

    final res = result;
    if (res == null) return const SizedBox.shrink();

    if (!res.isSuccess) {
      return Container(
        margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 14,
              color: AppColors.error,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                res.errorMessage ?? 'Không thể dịch tin nhắn này.',
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onRetry,
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: ChatStyles.tealSoftBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChatStyles.tealBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ChatStyles.tealPillBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  res.languagePairLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: ChatStyles.tealDark,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Bản dịch',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ChatStyles.tealDark,
                ),
              ),
              if (onPickWords != null) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: onPickWords,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bookmark_add_outlined,
                          size: 13,
                          color: ChatStyles.tealPrimary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Tách từ & Lưu',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: ChatStyles.tealPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (onHide != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onHide,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            res.translatedText,
            style: const TextStyle(
              fontSize: 13.2,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.38,
            ),
          ),
        ],
      ),
    );
  }
}
