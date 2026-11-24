import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth_profile/data/models/language_model.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/room_join_request.dart';
import '../../data/repositories/chat_repository.dart';

/// Quản lý trạng thái danh sách Phòng Chat của tôi, Khám phá phòng nhóm & Bộ lọc.
class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatRepository? repository})
      : _repository = repository ?? ChatRepository();

  final ChatRepository _repository;

  List<ConversationModel> _myRooms = const [];
  List<ConversationModel> _discoverRooms = const [];
  List<LanguageModel> _languages = const [];

  bool _isLoading = false;
  bool _isCreating = false;
  String? _busyRoomId;
  String? _errorMessage;

  String _searchQuery = '';
  String? _selectedLang;
  String? _selectedLevel;

  // Trạng thái tin nhắn Realtime của phòng đang mở
  String? _activeRoomId;
  List<MessageModel> _roomMessages = const [];
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;
  String? _messageError;
  RealtimeChannel? _roomChannel;
  final Map<String, ({String name, String? avatarUrl})> _senderCache = {};

  List<ConversationModel> get myRooms => _myRooms;
  List<ConversationModel> get discoverRooms => _discoverRooms;
  List<LanguageModel> get languages => _languages;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get busyRoomId => _busyRoomId;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedLang => _selectedLang;
  String? get selectedLevel => _selectedLevel;

  List<MessageModel> get roomMessages => _roomMessages;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSendingMessage => _isSendingMessage;
  String? get messageError => _messageError;

  Future<void> loadRooms(String userId, {bool silent = false}) async {
    if (!_repository.isReady) {
      _errorMessage = 'Chưa kết nối Supabase. Hãy chạy app kèm file .env.';
      notifyListeners();
      return;
    }

    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _repository.fetchMyConversations(userId),
        _repository.fetchPublicGroupRooms(
          userId: userId,
          searchQuery: _searchQuery,
          targetLang: _selectedLang,
          level: _selectedLevel,
        ),
        if (_languages.isEmpty)
          _repository.fetchAllowedLanguages()
        else
          Future.value(_languages),
      ]);

      _myRooms = results[0] as List<ConversationModel>;
      _discoverRooms = results[1] as List<ConversationModel>;
      _languages = results[2] as List<LanguageModel>;
    } catch (e) {
      if (!silent) {
        _errorMessage = 'Không thể tải danh sách phòng chat: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilters({
    required String userId,
    String? searchQuery,
    String? targetLang,
    bool clearLang = false,
    String? level,
    bool clearLevel = false,
  }) async {
    if (searchQuery != null) _searchQuery = searchQuery;
    if (clearLang) {
      _selectedLang = null;
    } else if (targetLang != null) {
      _selectedLang = targetLang;
    }
    if (clearLevel) {
      _selectedLevel = null;
    } else if (level != null) {
      _selectedLevel = level;
    }

    if (!_repository.isReady) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _discoverRooms = await _repository.fetchPublicGroupRooms(
        userId: userId,
        searchQuery: _searchQuery,
        targetLang: _selectedLang,
        level: _selectedLevel,
      );
    } catch (e) {
      _errorMessage = 'Lỗi lọc danh sách phòng nhóm: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ConversationModel?> createGroupRoom({
    required String createdBy,
    required String managerName,
    required String name,
    required String description,
    String? level,
    required String targetLang,
    int? maxMembers,
    bool requireApproval = false,
  }) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _repository.createGroupRoom(
        createdBy: createdBy,
        managerName: managerName,
        name: name,
        description: description,
        level: level,
        targetLang: targetLang,
        maxMembers: maxMembers,
        requireApproval: requireApproval,
      );
      await loadRooms(createdBy);
      return created;
    } catch (e) {
      _errorMessage = 'Không thể tạo phòng nhóm: $e';
      notifyListeners();
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<bool> joinRoom({
    required String conversationId,
    required String userId,
    bool requireApproval = false,
  }) async {
    _busyRoomId = conversationId;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.joinRoom(
        conversationId: conversationId,
        userId: userId,
        requireApproval: requireApproval,
      );
      await loadRooms(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể tham gia phòng: $e';
      notifyListeners();
      return false;
    } finally {
      _busyRoomId = null;
      notifyListeners();
    }
  }

  Future<List<RoomJoinRequest>> fetchPendingRequests(String conversationId) {
    return _repository.fetchPendingRequests(conversationId);
  }

  Future<bool> approveJoinRequest({
    required String conversationId,
    required String targetUserId,
    required String currentUserId,
  }) async {
    try {
      await _repository.approveJoinRequest(
        conversationId: conversationId,
        targetUserId: targetUserId,
      );
      await loadRooms(currentUserId);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể duyệt thành viên: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectJoinRequest({
    required String conversationId,
    required String targetUserId,
    required String currentUserId,
  }) async {
    try {
      await _repository.rejectJoinRequest(
        conversationId: conversationId,
        targetUserId: targetUserId,
      );
      await loadRooms(currentUserId);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể từ chối yêu cầu: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveRoom({
    required String conversationId,
    required String userId,
  }) async {
    _busyRoomId = conversationId;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.leaveRoom(
        conversationId: conversationId,
        userId: userId,
      );
      await loadRooms(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể rời phòng: $e';
      notifyListeners();
      return false;
    } finally {
      _busyRoomId = null;
      notifyListeners();
    }
  }

  // ==================== TIN NHẮN REALTIME TRONG PHÒNG ====================

  /// Tải lịch sử tin nhắn từ Supabase & mở kênh WebSocket lắng nghe tin nhắn mới
  Future<void> openRoomMessages(String conversationId) async {
    _detachRoomChannel();
    _activeRoomId = conversationId;
    _roomMessages = const [];
    _messageError = null;

    if (!_repository.isReady) {
      _messageError = 'Chưa kết nối Supabase.';
      notifyListeners();
      return;
    }

    _isLoadingMessages = true;
    notifyListeners();

    try {
      final fetched = await _repository.fetchMessages(conversationId);
      if (_activeRoomId != conversationId) return;

      for (final msg in fetched) {
        _senderCache[msg.senderId] = (
          name: msg.senderName,
          avatarUrl: msg.senderAvatarUrl,
        );
      }
      _roomMessages = fetched;

      _roomChannel = _repository.subscribeToRoomMessages(
        conversationId: conversationId,
        onNewMessage: _handleRealtimeMessage,
      );
    } catch (e) {
      if (_activeRoomId != conversationId) return;
      _messageError = 'Không thể tải lịch sử tin nhắn: $e';
    } finally {
      if (_activeRoomId == conversationId) {
        _isLoadingMessages = false;
        notifyListeners();
      }
    }
  }

  void _handleRealtimeMessage(MessageModel incoming) {
    if (incoming.conversationId != _activeRoomId) return;
    if (_roomMessages.any((m) => m.id == incoming.id)) return;

    final cached = _senderCache[incoming.senderId];
    final enriched = cached != null
        ? incoming.copyWith(
            senderName: cached.name,
            senderAvatarUrl: cached.avatarUrl,
          )
        : incoming;

    _roomMessages = [..._roomMessages, enriched];
    notifyListeners();

    if (cached == null) {
      _resolveSenderAndPatch(incoming.id, incoming.senderId);
    }
  }

  Future<void> _resolveSenderAndPatch(String messageId, String senderId) async {
    try {
      final info = await _repository.fetchSenderProfile(senderId);
      _senderCache[senderId] = info;
      _roomMessages = _roomMessages
          .map(
            (m) => m.id == messageId
                ? m.copyWith(
                    senderName: info.name,
                    senderAvatarUrl: info.avatarUrl,
                  )
                : m,
          )
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  /// Gửi tin nhắn mới vào Supabase & hiển thị ngay trên khung chat
  Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    _isSendingMessage = true;
    _messageError = null;
    notifyListeners();

    try {
      _senderCache[senderId] = (name: senderName, avatarUrl: senderAvatarUrl);
      final saved = await _repository.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        content: trimmed,
      );

      if (_activeRoomId == conversationId &&
          !_roomMessages.any((m) => m.id == saved.id)) {
        _roomMessages = [..._roomMessages, saved];
      }
      return true;
    } catch (e) {
      _messageError = 'Không thể gửi tin nhắn: $e';
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Đóng kết nối WebSocket khi rời khỏi phòng chat
  void closeRoomMessages() {
    _detachRoomChannel();
    _activeRoomId = null;
    _roomMessages = const [];
    _messageError = null;
    _isLoadingMessages = false;
    _isSendingMessage = false;
  }

  void _detachRoomChannel() {
    final ch = _roomChannel;
    _roomChannel = null;
    if (ch != null) {
      _repository.unsubscribeChannel(ch);
    }
  }

  @override
  void dispose() {
    _detachRoomChannel();
    super.dispose();
  }
}
