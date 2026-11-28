import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../styles/chat_room_styles.dart';
import '../styles/chat_styles.dart';

/// Thanh nhập tin nhắn dưới đáy Phòng Chat (tông Xanh Ngọc, nút Gợi ý chủ đề & nút Gửi tròn)
class ChatMessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onSuggestTopicTap;
  final bool isSending;

  const ChatMessageComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onSuggestTopicTap,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: ChatRoomStyles.composerDecoration,
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onSuggestTopicTap,
            tooltip: 'Gợi ý chủ đề & câu mở đầu',
            style: IconButton.styleFrom(
              backgroundColor: ChatStyles.tealSoftBg,
              foregroundColor: ChatStyles.tealDark,
              fixedSize: const Size(40, 40),
            ),
            icon: const Icon(Icons.lightbulb_outline_rounded, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                hintStyle: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textMuted,
                ),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF3F6F8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: Color(0xFFE2ECEE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: Color(0xFFE2ECEE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(
                    color: ChatStyles.tealPrimary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            onPressed: isSending ? null : onSend,
            tooltip: 'Gửi tin nhắn',
            style: IconButton.styleFrom(
              backgroundColor: ChatStyles.tealPrimary,
              foregroundColor: Colors.white,
              fixedSize: const Size(42, 42),
            ),
            icon: isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}
