import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/presentation/providers/auth_provider.dart';
import '../../data/models/conversation_model.dart';
import '../components/chat_message_composer.dart';
import '../components/chat_room_header.dart';
import '../styles/chat_room_styles.dart';

class _DraftMessage {
  final String senderName;
  final String content;
  final DateTime sentAt;

  const _DraftMessage({
    required this.senderName,
    required this.content,
    required this.sentAt,
  });
}

/// Giao diện bên trong một Phòng Chat (Đợt 3 — chỉ UI khung phòng, chưa nối Realtime WebSocket).
/// Hiển thị ngay trong vùng Outlet của MainLayout, giữ nguyên Sidebar & Header bên ngoài.
class ChatRoomView extends StatefulWidget {
  final ConversationModel room;
  final VoidCallback onBack;
  final VoidCallback? onLeaveRoom;

  const ChatRoomView({
    super.key,
    required this.room,
    required this.onBack,
    this.onLeaveRoom,
  });

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_DraftMessage> _previewMessages = [];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature sẽ được tích hợp ở đợt tiếp theo.')),
    );
  }

  void _handleSendPreview() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final sender =
        context.read<AuthProvider>().currentProfile?.displayName ?? 'Bạn';

    setState(() {
      _previewMessages.add(
        _DraftMessage(
          senderName: sender.isNotEmpty ? sender : 'Bạn',
          content: text,
          sentAt: DateTime.now(),
        ),
      );
      _messageController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          decoration: ChatRoomStyles.shellDecoration,
          child: Column(
            children: [
              ChatRoomHeader(
                room: widget.room,
                onBack: widget.onBack,
                onStartSessionTap: () =>
                    _showComingSoon('Đồng hồ bấm giờ buổi luyện tập'),
                onLeaveRoom: widget.onLeaveRoom,
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC),
                  child: _previewMessages.isEmpty
                      ? _buildEmptyConversation()
                      : _buildMessageList(),
                ),
              ),
              ChatMessageComposer(
                controller: _messageController,
                onSend: _handleSendPreview,
                onSuggestTopicTap: () =>
                    _showComingSoon('Gợi ý chủ đề & câu mở đầu hội thoại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyConversation() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Chào mừng đến với ${widget.room.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.room.description.isNotEmpty
                    ? widget.room.description
                    : 'Chưa có tin nhắn nào trong phòng. Hãy gửi lời chào mở đầu để bắt đầu luyện giao tiếp!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (widget.room.isGroup)
                    _InfoChip(
                      icon: Icons.translate_rounded,
                      label:
                          '${widget.room.targetLang.toUpperCase()} • ${widget.room.level}',
                    ),
                  if (widget.room.topicCategory.isNotEmpty)
                    _InfoChip(
                      icon: Icons.topic_outlined,
                      label: widget.room.topicCategory,
                    ),
                  if (widget.room.isGroup)
                    _InfoChip(
                      icon: Icons.people_outline_rounded,
                      label:
                          '${widget.room.memberCount}/${widget.room.maxMembers} thành viên',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _previewMessages.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, index) {
        final msg = _previewMessages[index];
        return Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${msg.senderName} • ${_formatTime(msg.sentAt)}',
                  style: ChatRoomStyles.roomHeaderMeta,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: ChatRoomStyles.messageBubble(isMine: true),
                  child: Text(
                    msg.content,
                    style: ChatRoomStyles.messageText(isMine: true),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
