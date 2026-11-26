import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth_profile/data/models/language_model.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/meet_session_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/online_member_model.dart';
import '../../data/models/room_join_request.dart';
import '../../data/models/room_member_model.dart';
import '../../data/repositories/chat_repository.dart';

/// Quản lý trạng thái danh sách Phòng Chat của tôi, Khám phá phòng nhóm & Bộ lọc.
class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatRepository? repository})
      : _repository = repository ?? ChatRepository();

  final ChatRepository _repository;

  List<ConversationModel> _myRooms = const [];
  List<ConversationModel> _discoverRooms = const [];
  List<LanguageModel> _languages = const [];
  List<OnlineMemberModel> _onlineMembers = const [];

  bool _isLoading = false;
  bool _isCreating = false;
  String? _busyRoomId;
  String? _errorMessage;

  String _searchQuery = '';
  String? _selectedLang;
  String? _selectedLevel;

  // Trạng thái tin nhắn, thành viên & lịch học Meet của phòng đang mở
  String? _activeRoomId;
  List<MessageModel> _roomMessages = const [];
  List<RoomMemberModel> _roomMembers = const [];
  MeetSessionModel? _activeMeetSession;
  bool _isLoadingMessages = false;
  bool _isLoadingMembers = false;
  bool _isSendingMessage = false;
  String? _messageError;
  RealtimeChannel? _roomChannel;
  RealtimeChannel? _meetChannel;
  final Map<String, ({String name, String? avatarUrl})> _senderCache = {};

  List<ConversationModel> get myRooms => _myRooms;
  List<ConversationModel> get discoverRooms => _discoverRooms;
  List<LanguageModel> get languages => _languages;
  List<OnlineMemberModel> get onlineMembers => _onlineMembers;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get busyRoomId => _busyRoomId;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedLang => _selectedLang;
  String? get selectedLevel => _selectedLevel;

  List<MessageModel> get roomMessages => _roomMessages;
  List<RoomMemberModel> get roomMembers => _roomMembers;
  MeetSessionModel? get activeMeetSession => _activeMeetSession;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isLoadingMembers => _isLoadingMembers;
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
        _repository.fetchOnlineMembers(excludeUserId: userId),
      ]);

      _myRooms = results[0] as List<ConversationModel>;
      _discoverRooms = results[1] as List<ConversationModel>;
      _languages = results[2] as List<LanguageModel>;
      _onlineMembers = results[3] as List<OnlineMemberModel>;
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
    String? coverUrl,
    String? roomFocus,
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
        coverUrl: coverUrl,
        roomFocus: roomFocus,
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

      _activeMeetSession =
          await _repository.fetchActiveMeetSession(conversationId);
      _meetChannel = _repository.subscribeToRoomMeetSessions(
        conversationId: conversationId,
        onChanged: () => _refreshActiveMeet(conversationId),
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

  /// Gửi tin nhắn mới vào Supabase & hiển thị ngay trên khung chat.
  /// Lưu ý: Chuỗi lửa phòng chỉ cộng khi học đủ số phút quy định trong buổi Meet.
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

      _patchRoomAfterMessage(
        conversationId: conversationId,
        lastMessageText: trimmed,
        lastMessageAt: saved.createdAt,
      );

      return true;
    } catch (e) {
      _messageError = 'Không thể gửi tin nhắn: $e';
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  void _patchRoomAfterMessage({
    required String conversationId,
    required String lastMessageText,
    required DateTime lastMessageAt,
    int? streakCount,
    int? bestStreak,
    DateTime? lastChatDate,
  }) {
    ConversationModel patch(ConversationModel r) {
      if (r.id != conversationId) return r;
      return r.copyWith(
        lastMessageText: lastMessageText,
        lastMessageAt: lastMessageAt,
        roomStreakCount: streakCount,
        bestStreak: bestStreak,
        lastChatDate: lastChatDate,
      );
    }

    _myRooms = _myRooms.map(patch).toList();
    _discoverRooms = _discoverRooms.map(patch).toList();
  }

  /// Lấy bản cập nhật mới nhất của 1 phòng từ bộ nhớ Provider (gồm chuỗi lửa mới nhất)
  ConversationModel findRoomOrFallback(ConversationModel fallback) {
    for (final r in _myRooms) {
      if (r.id == fallback.id) return r;
    }
    for (final r in _discoverRooms) {
      if (r.id == fallback.id) return r;
    }
    return fallback;
  }

  /// Đóng kết nối WebSocket khi rời khỏi phòng chat
  void closeRoomMessages() {
    _detachRoomChannel();
    _activeRoomId = null;
    _roomMessages = const [];
    _roomMembers = const [];
    _activeMeetSession = null;
    _messageError = null;
    _isLoadingMessages = false;
    _isLoadingMembers = false;
    _isSendingMessage = false;
  }

  Future<void> _refreshActiveMeet(String conversationId) async {
    if (_activeRoomId != conversationId) return;
    _activeMeetSession =
        await _repository.fetchActiveMeetSession(conversationId);
    if (_activeRoomId == conversationId) {
      notifyListeners();
    }
  }

  /// Chủ phòng / Trợ giảng tạo buổi học Video Call Meet mới
  Future<MeetSessionModel?> scheduleMeetSession({
    required String conversationId,
    required String roomName,
    required String hostId,
    required String hostName,
    required String title,
    required DateTime scheduledAt,
    required int minMinutes,
    required bool startImmediately,
  }) async {
    try {
      final created = await _repository.createMeetSession(
        conversationId: conversationId,
        roomName: roomName,
        hostId: hostId,
        hostName: hostName,
        title: title,
        scheduledAt: scheduledAt,
        minMinutes: minMinutes,
        startImmediately: startImmediately,
      );
      if (_activeRoomId == conversationId) {
        _activeMeetSession = created;
        notifyListeners();
      }
      return created;
    } catch (e) {
      _messageError =
          'Không thể tạo lịch Meet (hãy chắc chắn đã chạy Migration 015): $e';
      notifyListeners();
      return null;
    }
  }

  /// Chủ phòng / Trợ giảng bắt đầu buổi đã hẹn (`live`) hoặc kết thúc buổi (`ended`)
  Future<bool> updateMeetStatus({
    required String sessionId,
    required String status,
  }) async {
    try {
      await _repository.updateMeetSessionStatus(
        sessionId: sessionId,
        status: status,
      );
      if (_activeMeetSession?.id == sessionId) {
        _activeMeetSession =
            status == 'ended' ? null : _activeMeetSession!.copyWith(status: status);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _messageError = 'Không thể cập nhật trạng thái buổi Meet: $e';
      notifyListeners();
      return false;
    }
  }

  Future<({int attendedSeconds, bool streakAwarded})> fetchMyMeetAttendance({
    required String sessionId,
    required String userId,
  }) =>
      _repository.fetchMyMeetAttendance(sessionId: sessionId, userId: userId);

  Future<List<MeetAttendanceModel>> fetchSessionAttendances(String sessionId) =>
      _repository.fetchSessionAttendances(sessionId);

  Future<int> fetchTodayPersonalMinutes(String userId) =>
      _repository.fetchTodayPersonalMinutes(userId);

  Future<void> saveMeetProgress({
    required String sessionId,
    required String userId,
    required int attendedSeconds,
    required bool streakAwarded,
  }) =>
      _repository.saveMeetAttendanceProgress(
        sessionId: sessionId,
        userId: userId,
        attendedSeconds: attendedSeconds,
        streakAwarded: streakAwarded,
      );

  /// Ghi nhận khi thành viên đã học ĐỦ phút tối thiểu trong buổi Meet:
  /// - Tầng 1: Cộng +1 chuỗi lửa riêng của phòng (`conversation_members`)
  /// - Tầng 2: Cộng dồn phút vào mục tiêu cá nhân hôm nay (`user_quest_logs` -> `profiles.streak_count`)
  Future<
      ({
        int? roomStreak,
        bool roomStreakIncremented,
        int? personalTodayMinutes,
        int? personalStreak,
        int? personalBestStreak,
        bool personalGoalReached,
      })> awardMeetStreak({
    required String sessionId,
    required String conversationId,
    required String userId,
    required int attendedSeconds,
    required int addMinutesToDaily,
    required int dailyGoalMinutes,
  }) async {
    await _repository.saveMeetAttendanceProgress(
      sessionId: sessionId,
      userId: userId,
      attendedSeconds: attendedSeconds,
      streakAwarded: true,
    );

    final roomStreakRes = await _repository.recordRoomChatStreak(
      conversationId: conversationId,
      userId: userId,
    );

    if (roomStreakRes != null) {
      _patchRoomStreak(
        conversationId: conversationId,
        streakCount: roomStreakRes.streakCount,
        bestStreak: roomStreakRes.bestStreak,
        lastChatDate: roomStreakRes.lastChatDate,
      );
      notifyListeners();
    }

    final personalRes = await _repository.recordPersonalDailyMeetMinutes(
      userId: userId,
      addMinutes: addMinutesToDaily,
      dailyGoalMinutes: dailyGoalMinutes,
    );

    return (
      roomStreak: roomStreakRes?.streakCount,
      roomStreakIncremented: roomStreakRes?.incrementedToday ?? false,
      personalTodayMinutes: personalRes?.todayMinutes,
      personalStreak: personalRes?.streakCount,
      personalBestStreak: personalRes?.bestStreak,
      personalGoalReached: personalRes?.goalReached ?? false,
    );
  }

  void _patchRoomStreak({
    required String conversationId,
    required int streakCount,
    required int bestStreak,
    required DateTime lastChatDate,
  }) {
    ConversationModel patch(ConversationModel r) => r.id == conversationId
        ? r.copyWith(
            roomStreakCount: streakCount,
            bestStreak: bestStreak,
            lastChatDate: lastChatDate,
          )
        : r;
    _myRooms = _myRooms.map(patch).toList();
    _discoverRooms = _discoverRooms.map(patch).toList();
  }

  /// Tải danh sách thành viên phòng (Chủ phòng / Phó phòng / Thành viên) cho Panel Thông tin phòng
  Future<void> loadRoomMembers(String conversationId) async {
    if (!_repository.isReady) return;
    _isLoadingMembers = true;
    notifyListeners();

    try {
      _roomMembers = await _repository.fetchRoomMembers(conversationId);
    } catch (e) {
      debugPrint('[ChatProvider] Khong the tai danh sach thanh vien: $e');
    } finally {
      _isLoadingMembers = false;
      notifyListeners();
    }
  }

  /// Chủ phòng bổ nhiệm / gỡ quyền Phó phòng (Trợ giảng)
  Future<bool> setMemberRole({
    required String conversationId,
    required String targetUserId,
    required String newRole,
    required String actorId,
    required String roomName,
  }) async {
    try {
      await _repository.updateMemberRole(
        conversationId: conversationId,
        targetUserId: targetUserId,
        newRole: newRole,
        actorId: actorId,
        roomName: roomName,
      );
      _roomMembers = _roomMembers
          .map((m) => m.userId == targetUserId ? m.copyWith(role: newRole) : m)
          .toList()
        ..sort((a, b) {
          final cmp = a.roleSortOrder.compareTo(b.roleSortOrder);
          return cmp != 0 ? cmp : b.effectiveStreak.compareTo(a.effectiveStreak);
        });
      notifyListeners();
      return true;
    } catch (e) {
      _messageError =
          'Không thể cập nhật vai trò (hãy chắc chắn đã chạy Migration 014): $e';
      notifyListeners();
      return false;
    }
  }

  /// Chủ phòng hoặc Phó phòng mời thành viên vi phạm ra khỏi phòng
  Future<bool> kickMember({
    required String conversationId,
    required String targetUserId,
    required String currentUserId,
  }) async {
    try {
      await _repository.leaveRoom(
        conversationId: conversationId,
        userId: targetUserId,
      );
      _roomMembers =
          _roomMembers.where((m) => m.userId != targetUserId).toList();
      await loadRooms(currentUserId, silent: true);
      notifyListeners();
      return true;
    } catch (e) {
      _messageError = 'Không thể mời thành viên ra khỏi phòng: $e';
      notifyListeners();
      return false;
    }
  }

  /// Chủ phòng hoặc Phó phòng cập nhật mô tả / nội quy phòng
  Future<bool> updateRoomDescription({
    required String conversationId,
    required String description,
  }) async {
    try {
      await _repository.updateRoomDescription(
        conversationId: conversationId,
        description: description,
      );
      ConversationModel patch(ConversationModel r) =>
          r.id == conversationId ? r.copyWith(description: description.trim()) : r;
      _myRooms = _myRooms.map(patch).toList();
      _discoverRooms = _discoverRooms.map(patch).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _messageError = 'Không thể cập nhật nội quy phòng: $e';
      notifyListeners();
      return false;
    }
  }

  void _detachRoomChannel() {
    final ch = _roomChannel;
    _roomChannel = null;
    if (ch != null) {
      _repository.unsubscribeChannel(ch);
    }
    final mch = _meetChannel;
    _meetChannel = null;
    if (mch != null) {
      _repository.unsubscribeChannel(mch);
    }
  }

  @override
  void dispose() {
    _detachRoomChannel();
    super.dispose();
  }
}
