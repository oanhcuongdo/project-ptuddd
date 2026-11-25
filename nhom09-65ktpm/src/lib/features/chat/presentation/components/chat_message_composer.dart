import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../styles/chat_room_styles.dart';

/// Thanh nhập tin nhắn dưới đáy Phòng Chat (kèm nút slot Gợi ý chủ đề & nút Gửi)
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
        vertical: AppSpacing.md,
      ),
      decoration: ChatRoomStyles.composerDecoration,
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onSuggestTopicTap,
            tooltip: 'Gợi ý chủ đề & câu mở đầu',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEEF2FF),
              foregroundColor: AppColors.primary,
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
                hintText: 'Nhập tin nhắn luyện giao tiếp...',
                isDense: true,
                filled: true,
                fillColor: AppColors.scaffoldWebStart,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
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
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
