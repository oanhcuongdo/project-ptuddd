import 'package:flutter/foundation.dart';

import '../../../auth_profile/data/models/language_model.dart';
import '../../data/models/conversation_model.dart';
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
}
