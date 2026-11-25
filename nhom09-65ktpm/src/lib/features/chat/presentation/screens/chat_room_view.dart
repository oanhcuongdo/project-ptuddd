import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/presentation/providers/auth_provider.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../components/chat_message_composer.dart';
import '../components/chat_room_header.dart';
import '../providers/chat_provider.dart';
import '../styles/chat_room_styles.dart';

/// Giao diện Phòng Chat Realtime (nối thẳng bảng `messages` & Supabase Realtime WebSocket).
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
  late final ChatProvider _chatProvider;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chatProvider.openRoomMessages(widget.room.id);
    });
  }

  @override
  void didUpdateWidget(covariant ChatRoomView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.id != widget.room.id) {
      _lastMessageCount = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _chatProvider.openRoomMessages(widget.room.id);
      });
    }
  }

  @override
  void dispose() {
    _chatProvider.closeRoomMessages();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature sẽ được tích hợp ở đợt tiếp theo.')),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final profile = context.read<AuthProvider>().currentProfile;
    if (profile == null) return;

    final senderName =
        profile.displayName.trim().isNotEmpty ? profile.displayName : 'Bạn';

    _messageController.clear();
    final ok = await _chatProvider.sendMessage(
      conversationId: widget.room.id,
      senderId: profile.userId,
      senderName: senderName,
      senderAvatarUrl: profile.avatarUrl,
      content: text,
    );

    if (!ok && mounted) {
      _messageController.text = text;
      _messageController.selection = TextSelection.collapsed(
        offset: text.length,
      );
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final currentUserId =
        context.watch<AuthProvider>().currentProfile?.userId;
    final messages = chat.roomMessages;

    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      if (messages.isNotEmpty) {
        _scrollToBottom();
      }
    }

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
              if (chat.messageError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 8,
                  ),
                  color: const Color(0xFFFEF2F2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          chat.messageError!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _chatProvider.openRoomMessages(widget.room.id),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 28),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC),
                  child: chat.isLoadingMessages && messages.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : messages.isEmpty
                          ? _buildEmptyConversation()
                          : _buildMessageList(messages, currentUserId),
                ),
              ),
              ChatMessageComposer(
                controller: _messageController,
                onSend: _handleSend,
                isSending: chat.isSendingMessage,
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
                          '${widget.room.targetLang.toUpperCase()} • ${widget.room.levelLabel}',
                    ),
                  if (widget.room.isGroup && widget.room.managerName.isNotEmpty)
                    _InfoChip(
                      icon: Icons.verified_user_outlined,
                      label: 'Quản lý: ${widget.room.managerName}',
                    ),
                  if (widget.room.isGroup)
                    _InfoChip(
                      icon: Icons.people_outline_rounded,
                      label: widget.room.memberSummary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(
    List<MessageModel> messages,
    String? currentUserId,
  ) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, index) {
        final msg = messages[index];
        final isMine = currentUserId != null && msg.senderId == currentUserId;

        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMine) ...[
                  _SenderAvatar(
                    name: msg.senderName,
                    avatarUrl: msg.senderAvatarUrl,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMine
                            ? _formatTime(msg.createdAt)
                            : '${msg.senderName} • ${_formatTime(msg.createdAt)}',
                        style: ChatRoomStyles.roomHeaderMeta,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration:
                            ChatRoomStyles.messageBubble(isMine: isMine),
                        child: Text(
                          msg.content,
                          style: ChatRoomStyles.messageText(isMine: isMine),
                        ),
                      ),
                    ],
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

class _SenderAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _SenderAvatar({required this.name, this.avatarUrl});

  String _initials(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'B';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _fallback() {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: Color(0xFFEEF2FF),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    if (url == null || !url.startsWith('http')) return _fallback();
    return ClipOval(
      child: Image.network(
        url,
        width: 30,
        height: 30,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      ),
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
