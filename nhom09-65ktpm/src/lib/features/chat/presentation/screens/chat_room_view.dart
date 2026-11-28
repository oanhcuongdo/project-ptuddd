import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/presentation/providers/auth_provider.dart';
import '../../../chat_online/models/translation_language.dart';
import '../../../chat_online/models/translation_result.dart';
import '../../../chat_online/services/translation_service.dart';
import '../../../vocab_notebook/data/repositories/vocab_repository.dart';
import '../../../vocab_notebook/presentation/providers/vocab_provider.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/meet_session_model.dart';
import '../../data/models/message_model.dart';
import '../components/chat_conversation_sidebar.dart';
import '../components/chat_meet_banner.dart';
import '../components/chat_message_composer.dart';
import '../components/chat_room_header.dart';
import '../components/chat_room_info_panel.dart';
import '../components/compose_translate_dialog.dart';
import '../components/inline_correction_bubble.dart';
import '../components/message_translation_footer.dart';
import '../components/message_word_picker_dialog.dart';
import '../components/schedule_meet_dialog.dart';
import '../helpers/chat_translate_helper.dart';
import '../providers/chat_provider.dart';
import '../styles/chat_room_styles.dart';
import '../styles/chat_styles.dart';
import 'room_meet_call_view.dart';

/// Giao diện Phòng Chat Realtime dạng 2 cột kiểu Messenger/Zalo ngay bên trong tab Phòng học:
/// - Cột trái (màn rộng >= 860px): Danh sách các phòng bạn đã tham gia + nút Back về trang Phòng học
/// - Cột phải: Khung nhắn tin Realtime WebSocket + Chuỗi lửa phòng + Thanh nhập tin nhắn
class ChatRoomView extends StatefulWidget {
  final ConversationModel room;
  final ValueChanged<ConversationModel>? onSelectRoom;
  final VoidCallback onBack;
  final VoidCallback? onLeaveRoom;

  const ChatRoomView({
    super.key,
    required this.room,
    this.onSelectRoom,
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
  bool _showInfoPanel = false;
  bool _autoTranslateEnabled = false;
  MeetSessionModel? _joinedMeetSession;
  final _translationService = TranslationService();
  final Map<String, TranslationResult> _translatedByMsgId = {};
  final Set<String> _translatingMsgIds = {};

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chatProvider.openRoomMessages(widget.room.id);
      _chatProvider.loadRoomMembers(widget.room.id);
    });
  }

  @override
  void didUpdateWidget(covariant ChatRoomView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.id != widget.room.id) {
      _lastMessageCount = 0;
      _messageController.clear();
      _translatedByMsgId.clear();
      _translatingMsgIds.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _chatProvider.openRoomMessages(widget.room.id);
        _chatProvider.loadRoomMembers(widget.room.id);
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

  Future<void> _translateMessage(MessageModel msg) async {
    if (_translatingMsgIds.contains(msg.id)) return;
    final plainText = ChatTranslateHelper.plainTextForTranslation(msg.content);
    if (plainText.isEmpty) return;

    setState(() => _translatingMsgIds.add(msg.id));
    final result = await _translationService.translate(
      text: plainText,
      from: 'auto',
      to: 'vi',
    );
    if (!mounted) return;
    setState(() {
      _translatingMsgIds.remove(msg.id);
      _translatedByMsgId[msg.id] = result;
    });
  }

  void _toggleMessageTranslation(MessageModel msg) {
    if (_translatedByMsgId.containsKey(msg.id)) {
      setState(() => _translatedByMsgId.remove(msg.id));
      return;
    }
    _translateMessage(msg);
  }

  void _toggleAutoTranslate(
    List<MessageModel> messages,
    String? currentUserId,
  ) {
    final nextValue = !_autoTranslateEnabled;
    setState(() {
      _autoTranslateEnabled = nextValue;
      if (!nextValue) {
        _translatedByMsgId.clear();
        _translatingMsgIds.clear();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ChatStyles.tealDark,
        duration: const Duration(seconds: 2),
        content: Text(
          nextValue
              ? 'Đã bật Tự động dịch mọi tin nhắn đến sang Tiếng Việt.'
              : 'Đã tắt Tự động dịch và ẩn toàn bộ bản dịch.',
        ),
      ),
    );

    if (nextValue) {
      _autoTranslatePendingMessages(messages, currentUserId);
    }
  }

  void _autoTranslatePendingMessages(
    List<MessageModel> messages,
    String? currentUserId,
  ) {
    if (!_autoTranslateEnabled) return;
    for (final msg in messages) {
      final isMine = currentUserId != null && msg.senderId == currentUserId;
      if (isMine) continue;
      if (_translatedByMsgId.containsKey(msg.id) ||
          _translatingMsgIds.contains(msg.id)) {
        continue;
      }
      final plainText = ChatTranslateHelper.plainTextForTranslation(msg.content);
      if (plainText.isEmpty ||
          TranslationService.containsVietnameseDiacritics(plainText)) {
        continue;
      }
      _translateMessage(msg);
    }
  }

  Future<void> _openComposeTranslate(ConversationModel liveRoom) async {
    final preferredLang = TranslationLanguage.fromCode(liveRoom.targetLang);
    final defaultTarget = preferredLang == TranslationLanguage.vi ||
            preferredLang == TranslationLanguage.auto
        ? TranslationLanguage.en
        : preferredLang;

    final res = await ComposeTranslateDialog.show(
      context,
      initialText: _messageController.text,
      defaultTargetLang: defaultTarget,
      translationService: _translationService,
    );
    if (!mounted || res == null) return;

    if (res.action == ComposeTranslateAction.replaceInput) {
      _messageController.text = res.translatedText;
      _messageController.selection = TextSelection.collapsed(
        offset: res.translatedText.length,
      );
      return;
    }

    final profile = context.read<AuthProvider>().currentProfile;
    if (profile == null) return;
    final senderName =
        profile.displayName.trim().isNotEmpty ? profile.displayName : 'Bạn';

    final bilingualContent = ChatTranslateHelper.encodeBilingual(
      primaryText: res.translatedText,
      secondaryText: res.originalText,
    );
    _messageController.clear();
    await _chatProvider.sendMessage(
      conversationId: widget.room.id,
      senderId: profile.userId,
      senderName: senderName,
      senderAvatarUrl: profile.avatarUrl,
      content: bilingualContent,
    );
  }

  Future<void> _openInlineCorrection(MessageModel msg) async {
    final draft = await InlineCorrectionDialog.show(
      context,
      originalText: msg.content,
    );
    if (!mounted || draft == null) return;

    final profile = context.read<AuthProvider>().currentProfile;
    if (profile == null) return;
    final senderName =
        profile.displayName.trim().isNotEmpty ? profile.displayName : 'Bạn';

    final encoded = ChatTranslateHelper.encodeCorrection(
      originalText: draft.originalText,
      correctedText: draft.correctedText,
      note: draft.note,
    );

    await _chatProvider.sendMessage(
      conversationId: widget.room.id,
      senderId: profile.userId,
      senderName: senderName,
      senderAvatarUrl: profile.avatarUrl,
      content: encoded,
    );
  }

  void _openWordPicker(MessageModel msg) {
    VocabProvider? vocabProvider;
    try {
      vocabProvider = Provider.of<VocabProvider>(context, listen: false);
    } on ProviderNotFoundException {
      vocabProvider = null;
    }

    final currentUserId = context.read<AuthProvider>().currentProfile?.userId;

    MessageWordPickerDialog.show(
      context,
      rawMessageContent: msg.content,
      translationService: _translationService,
      onSaveWord: ({
        required word,
        required translatedMeaning,
        required sourceLang,
        required targetLang,
        required exampleSentence,
      }) async {
        if (vocabProvider != null) {
          final saved = await vocabProvider.addOrUpdateWord(
            word: word,
            translatedMeaning: translatedMeaning,
            sourceLang: sourceLang,
            targetLang: targetLang,
            exampleSentence: exampleSentence,
          );
          return saved != null;
        }
        if (currentUserId == null) return false;
        try {
          await VocabRepository().addVocabEntry(
            userId: currentUserId,
            word: word,
            translatedMeaning: translatedMeaning,
            sourceLang: sourceLang,
            targetLang: targetLang,
            exampleSentence: exampleSentence,
          );
          return true;
        } catch (_) {
          return false;
        }
      },
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

  Future<void> _openScheduleMeetDialog(ConversationModel liveRoom) async {
    final profile = context.read<AuthProvider>().currentProfile;
    if (profile == null) return;
    final hostName = profile.displayName.trim().isNotEmpty
        ? profile.displayName
        : 'Trợ giảng';

    final created = await showDialog<MeetSessionModel>(
      context: context,
      builder: (_) => ScheduleMeetDialog(
        room: liveRoom,
        hostId: profile.userId,
        hostName: hostName,
      ),
    );
    if (!mounted || created == null) return;

    if (created.isLive) {
      setState(() => _joinedMeetSession = created);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ChatStyles.tealDark,
          content: Text(
            'Đã hẹn lịch buổi "${created.title}" và gửi thông báo cho cả phòng!',
          ),
        ),
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
    final liveRoom = chat.findRoomOrFallback(widget.room);
    final currentUserId =
        context.watch<AuthProvider>().currentProfile?.userId;
    final messages = chat.roomMessages;
    final activeMeet = chat.activeMeetSession;

    // Nếu người dùng đang tham gia phòng Video Call Meet -> hiển thị màn hình Meet nhúng trực tiếp
    if (_joinedMeetSession != null) {
      return RoomMeetCallView(
        room: liveRoom,
        session: _joinedMeetSession!,
        onExit: () => setState(() => _joinedMeetSession = null),
      );
    }

    final isCreator =
        currentUserId != null && liveRoom.createdBy == currentUserId;
    var canManageRoom = isCreator || liveRoom.canManageRoom;
    if (currentUserId != null) {
      for (final m in chat.roomMembers) {
        if (m.userId == currentUserId) {
          canManageRoom = isCreator || m.isOwner || m.isCoOwner;
          break;
        }
      }
    }

    // Đảm bảo danh sách phòng cột trái luôn có ít nhất phòng đang mở
    final joinedRooms = chat.myRooms.any((r) => r.id == liveRoom.id)
        ? chat.myRooms
        : [liveRoom, ...chat.myRooms];

    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      if (messages.isNotEmpty) {
        _scrollToBottom();
        if (_autoTranslateEnabled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _autoTranslatePendingMessages(messages, currentUserId);
          });
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showConversationList = constraints.maxWidth >= 820;
          final canDockInfoPanel = constraints.maxWidth >= 1060;

          void handleToggleInfoPanel() {
            _chatProvider.loadRoomMembers(liveRoom.id);
            if (canDockInfoPanel) {
              setState(() => _showInfoPanel = !_showInfoPanel);
            } else {
              showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SizedBox(
                    width: 320,
                    height: 600,
                    child: ChatRoomInfoPanel(
                      room: liveRoom,
                      currentUserId: currentUserId,
                      messages: messages,
                      onClose: () => Navigator.of(context).pop(),
                      onLeaveRoom: widget.onLeaveRoom == null
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              widget.onLeaveRoom?.call();
                            },
                    ),
                  ),
                ),
              );
            }
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              decoration: ChatRoomStyles.shellDecoration,
              child: Row(
                children: [
                  if (showConversationList)
                    ChatConversationSidebar(
                      rooms: joinedRooms,
                      activeRoomId: liveRoom.id,
                      onBack: widget.onBack,
                      onSelectRoom: (selected) {
                        if (selected.id == liveRoom.id) return;
                        widget.onSelectRoom?.call(selected);
                      },
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        ChatRoomHeader(
                          room: liveRoom,
                          showBackButton: !showConversationList,
                          isInfoPanelOpen: canDockInfoPanel && _showInfoPanel,
                          canScheduleMeet: canManageRoom,
                          hasLiveMeet: activeMeet?.isLive ?? false,
                          isAutoTranslateEnabled: _autoTranslateEnabled,
                          onToggleAutoTranslate: () =>
                              _toggleAutoTranslate(messages, currentUserId),
                          onToggleInfoPanel: handleToggleInfoPanel,
                          onBack: widget.onBack,
                          onMeetActionTap: () {
                            if (activeMeet != null && activeMeet.isLive) {
                              setState(() => _joinedMeetSession = activeMeet);
                            } else if (canManageRoom) {
                              _openScheduleMeetDialog(liveRoom);
                            }
                          },
                        ),
                        if (activeMeet != null && !activeMeet.isEnded)
                          ChatMeetBanner(
                            session: activeMeet,
                            canManage: canManageRoom,
                            onJoinMeet: () =>
                                setState(() => _joinedMeetSession = activeMeet),
                            onStartNow: () async {
                              final ok = await _chatProvider.updateMeetStatus(
                                sessionId: activeMeet.id,
                                status: 'live',
                              );
                              if (ok && mounted) {
                                setState(
                                  () => _joinedMeetSession =
                                      activeMeet.copyWith(status: 'live'),
                                );
                              }
                            },
                            onEndSession: () => _chatProvider.updateMeetStatus(
                              sessionId: activeMeet.id,
                              status: 'ended',
                            ),
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
                                  onPressed: () => _chatProvider
                                      .openRoomMessages(widget.room.id),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(0, 28),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: Container(
                            color: const Color(0xFFF8FAFB),
                            child: chat.isLoadingMessages && messages.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: ChatStyles.tealPrimary,
                                    ),
                                  )
                                : messages.isEmpty
                                    ? _buildEmptyConversation(liveRoom)
                                    : _buildMessageList(
                                        messages,
                                        currentUserId,
                                      ),
                          ),
                        ),
                        ChatMessageComposer(
                          controller: _messageController,
                          onSend: _handleSend,
                          isSending: chat.isSendingMessage,
                          onTranslateInputTap: () =>
                              _openComposeTranslate(liveRoom),
                          onSuggestTopicTap: () => _showComingSoon(
                            'Gợi ý chủ đề & câu mở đầu hội thoại',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canDockInfoPanel && _showInfoPanel)
                    ChatRoomInfoPanel(
                      room: liveRoom,
                      currentUserId: currentUserId,
                      messages: messages,
                      onClose: () => setState(() => _showInfoPanel = false),
                      onLeaveRoom: widget.onLeaveRoom,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyConversation(ConversationModel room) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: ChatStyles.tealSoftBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ChatStyles.tealBorder),
                ),
                child: const Icon(
                  Icons.headset_mic_rounded,
                  size: 34,
                  color: ChatStyles.tealPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Bắt đầu cuộc trò chuyện nào!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                room.description.isNotEmpty
                    ? room.description
                    : 'Hãy trao đổi cùng mọi người và tham gia buổi học Video Call Meet trong phòng "${room.name}" để giữ chuỗi lửa nhé!',
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
                  if (room.isGroup)
                    _InfoChip(
                      icon: Icons.translate_rounded,
                      label:
                          '${room.targetLang.toUpperCase()} • ${room.levelLabel}',
                    ),
                  if (room.isGroup && room.managerName.isNotEmpty)
                    _InfoChip(
                      icon: Icons.verified_user_outlined,
                      label: 'Quản lý: ${room.managerName}',
                    ),
                  if (room.isGroup)
                    _InfoChip(
                      icon: Icons.people_outline_rounded,
                      label: room.memberSummary,
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
    final roleByUserId = <String, String>{
      for (final m in _chatProvider.roomMembers) m.userId: m.role,
    };

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, index) {
        final msg = messages[index];
        final isMine = currentUserId != null && msg.senderId == currentUserId;
        final senderRole = roleByUserId[msg.senderId];

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
                      if (!isMine) ...[
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${msg.senderName} • ${_formatTime(msg.createdAt)}',
                              style: ChatRoomStyles.roomHeaderMeta,
                            ),
                            if (senderRole == 'owner' ||
                                senderRole == 'co_owner')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: senderRole == 'owner'
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  senderRole == 'owner'
                                      ? 'Chủ phòng'
                                      : 'Trợ giảng',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: senderRole == 'owner'
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF0369A1),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration:
                                  ChatRoomStyles.messageBubble(isMine: isMine),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildBubbleBody(msg.content, isMine),
                                  if (isMine) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatTime(msg.createdAt),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.white
                                                .withValues(alpha: 0.80),
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Icon(
                                          Icons.done_all_rounded,
                                          size: 13,
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (!isMine) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () => _toggleMessageTranslation(msg),
                              tooltip: _translatedByMsgId.containsKey(msg.id)
                                  ? 'Ẩn bản dịch'
                                  : 'Dịch nhanh sang Tiếng Việt',
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    _translatedByMsgId.containsKey(msg.id)
                                        ? ChatStyles.tealPillBg
                                        : Colors.white,
                                foregroundColor: ChatStyles.tealDark,
                                minimumSize: const Size(28, 28),
                                padding: const EdgeInsets.all(5),
                                side: const BorderSide(
                                  color: ChatStyles.tealBorder,
                                ),
                              ),
                              icon: const Icon(
                                Icons.translate_rounded,
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 2),
                            IconButton(
                              onPressed: () => _openInlineCorrection(msg),
                              tooltip: 'Sửa lỗi câu cho bạn học',
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF047857),
                                minimumSize: const Size(28, 28),
                                padding: const EdgeInsets.all(5),
                                side: const BorderSide(
                                  color: Color(0xFFA7F3D0),
                                ),
                              ),
                              icon: const Icon(
                                Icons.spellcheck_rounded,
                                size: 15,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (!isMine &&
                          (_translatingMsgIds.contains(msg.id) ||
                              _translatedByMsgId.containsKey(msg.id)))
                        MessageTranslationFooter(
                          result: _translatedByMsgId[msg.id],
                          isTranslating: _translatingMsgIds.contains(msg.id),
                          onPickWords: () => _openWordPicker(msg),
                          onRetry: () => _translateMessage(msg),
                          onHide: () =>
                              setState(() => _translatedByMsgId.remove(msg.id)),
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

  Widget _buildBubbleBody(String rawContent, bool isMine) {
    final correction = ChatTranslateHelper.parseCorrection(rawContent);
    if (correction != null) {
      return InlineCorrectionBubble(data: correction, isMine: isMine);
    }

    final bilingual = ChatTranslateHelper.parseBilingual(rawContent);
    if (bilingual != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bilingual.primaryText,
            style: ChatRoomStyles.messageText(isMine: isMine),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.divider,
                ),
              ),
            ),
            child: Text(
              bilingual.secondaryText,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isMine
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      rawContent,
      style: ChatRoomStyles.messageText(isMine: isMine),
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
        color: ChatStyles.tealPillBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: ChatStyles.tealDark,
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
          Icon(icon, size: 14, color: ChatStyles.tealPrimary),
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
