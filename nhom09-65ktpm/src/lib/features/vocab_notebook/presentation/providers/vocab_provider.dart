import 'package:flutter/foundation.dart';

import '../../data/models/vocab_entry_model.dart';
import '../../data/models/vocab_filter.dart';
import '../../data/repositories/vocab_repository.dart';

/// Quản lý trạng thái Sổ tay Từ vựng cá nhân (tải từ Supabase, tìm kiếm, lọc và thống kê tiến độ).
class VocabProvider extends ChangeNotifier {
  VocabProvider({VocabRepository? repository})
      : _repository = repository ?? VocabRepository();

  final VocabRepository _repository;

  List<VocabEntryModel> _entries = const [];
  VocabFilter _filter = const VocabFilter();
  String? _boundUserId;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _disposed = false;

  /// Toàn bộ từ vựng gốc của người dùng
  List<VocabEntryModel> get allEntries => _entries;

  /// Danh sách từ vựng sau khi áp dụng tìm kiếm, lọc ngôn ngữ, lọc trạng thái và sắp xếp
  List<VocabEntryModel> get filteredEntries => _filter.apply(_entries);

  /// Danh sách ưu tiên cho chế độ ôn tập Flashcard (đưa từ chưa thuộc lên trước)
  List<VocabEntryModel> get flashcardEntries {
    final learning = _entries.where((e) => !e.isMastered).toList();
    final mastered = _entries.where((e) => e.isMastered).toList();
    return [...learning, ...mastered];
  }

  VocabFilter get filter => _filter;
  String? get boundUserId => _boundUserId;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  int get totalCount => _entries.length;
  int get masteredCount => _entries.where((e) => e.isMastered).length;
  int get learningCount => totalCount - masteredCount;

  /// Tỷ lệ hoàn thành từ vựng từ 0.0 đến 1.0
  double get masteryProgress =>
      totalCount == 0 ? 0.0 : masteredCount / totalCount;

  /// Phần trăm hoàn thành làm tròn (0 - 100)
  int get masteryPercent => (masteryProgress * 100).round();

  /// Gắn phiên người dùng hiện tại và tải Sổ tay từ vựng từ Supabase
  void bindUser(String? userId) {
    if (userId == _boundUserId) return;
    _boundUserId = userId;
    _errorMessage = null;

    if (userId == null || userId.trim().isEmpty) {
      _entries = const [];
      _safeNotify();
      return;
    }

    if (_repository.isReady) {
      refresh(userId);
    }
  }

  /// Nạp dữ liệu thử nghiệm trực tiếp (hữu ích cho Unit/Widget Test)
  void seedEntries(List<VocabEntryModel> entries, {String? userId}) {
    _boundUserId = userId ?? _boundUserId;
    _entries = List<VocabEntryModel>.unmodifiable(entries);
    _errorMessage = null;
    _safeNotify();
  }

  /// Tải lại toàn bộ danh sách từ bảng `vocab_notebook`
  Future<void> refresh([String? explicitUserId]) async {
    final uid = explicitUserId ?? _boundUserId;
    if (uid == null || uid.trim().isEmpty || !_repository.isReady) return;

    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      _entries = await _repository.fetchUserVocab(uid);
    } catch (e) {
      _errorMessage = 'Không thể tải Sổ tay từ vựng: $e';
      debugPrint('[VocabProvider] $e');
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Thêm từ vựng mới (hoặc cập nhật nếu đã tồn tại cùng cặp ngôn ngữ)
  Future<VocabEntryModel?> addOrUpdateWord({
    required String word,
    required String translatedMeaning,
    String sourceLang = 'en',
    String targetLang = 'vi',
    String exampleSentence = '',
    bool isMastered = false,
  }) async {
    final uid = _boundUserId;
    if (uid == null || uid.trim().isEmpty) {
      _errorMessage = 'Vui lòng đăng nhập để lưu từ vào Sổ tay.';
      _safeNotify();
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final saved = await _repository.addVocabEntry(
        userId: uid,
        word: word,
        translatedMeaning: translatedMeaning,
        sourceLang: sourceLang,
        targetLang: targetLang,
        exampleSentence: exampleSentence,
        isMastered: isMastered,
      );

      final existingIndex = _entries.indexWhere((e) => e.id == saved.id);
      if (existingIndex >= 0) {
        final next = [..._entries];
        next[existingIndex] = saved;
        _entries = next;
      } else {
        _entries = [saved, ..._entries];
      }
      return saved;
    } catch (e) {
      _errorMessage = 'Không thể lưu từ mới: $e';
      debugPrint('[VocabProvider] Loi luu tu: $e');
      return null;
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  /// Cập nhật thông tin một mục từ vựng đã có
  Future<bool> updateEntry(VocabEntryModel updated) async {
    _isSaving = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final saved = await _repository.updateEntry(updated);
      _entries = _entries.map((e) => e.id == saved.id ? saved : e).toList();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật từ vựng: $e';
      debugPrint('[VocabProvider] Loi cap nhat: $e');
      return false;
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  /// Chuyển đổi trạng thái Đã thuộc / Đang học (`is_mastered`)
  Future<bool> toggleMastered(VocabEntryModel entry) async {
    final nextValue = !entry.isMastered;
    final previousEntries = _entries;

    _entries = _entries
        .map((e) => e.id == entry.id ? e.copyWith(isMastered: nextValue) : e)
        .toList();
    _safeNotify();

    if (!_repository.isReady) return true;

    try {
      final saved = await _repository.toggleMastered(
        entryId: entry.id,
        isMastered: nextValue,
      );
      _entries = _entries.map((e) => e.id == saved.id ? saved : e).toList();
      _safeNotify();
      return true;
    } catch (e) {
      _entries = previousEntries;
      _errorMessage = 'Không thể cập nhật trạng thái thuộc từ.';
      debugPrint('[VocabProvider] Loi toggleMastered: $e');
      _safeNotify();
      return false;
    }
  }

  /// Xóa một từ khỏi Sổ tay
  Future<bool> deleteEntry(String entryId) async {
    final previousEntries = _entries;
    _entries = _entries.where((e) => e.id != entryId).toList();
    _safeNotify();

    if (!_repository.isReady) return true;

    try {
      await _repository.deleteEntry(entryId);
      return true;
    } catch (e) {
      _entries = previousEntries;
      _errorMessage = 'Không thể xóa từ vựng khỏi Sổ tay.';
      debugPrint('[VocabProvider] Loi xoa tu: $e');
      _safeNotify();
      return false;
    }
  }

  void setSearchQuery(String query) {
    if (_filter.searchQuery == query) return;
    _filter = _filter.copyWith(searchQuery: query);
    _safeNotify();
  }

  void setLanguageFilter(String? langCode) {
    if (_filter.languageCode == langCode) return;
    _filter = langCode == null
        ? _filter.copyWith(clearLanguage: true)
        : _filter.copyWith(languageCode: langCode);
    _safeNotify();
  }

  void setMasteryFilter(VocabMasteryFilter masteryFilter) {
    if (_filter.masteryFilter == masteryFilter) return;
    _filter = _filter.copyWith(masteryFilter: masteryFilter);
    _safeNotify();
  }

  void setSortOrder(VocabSortOrder sortOrder) {
    if (_filter.sortOrder == sortOrder) return;
    _filter = _filter.copyWith(sortOrder: sortOrder);
    _safeNotify();
  }

  void resetFilters() {
    if (!_filter.hasActiveFilter &&
        _filter.sortOrder == VocabSortOrder.newest) {
      return;
    }
    _filter = _filter.reset();
    _safeNotify();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
