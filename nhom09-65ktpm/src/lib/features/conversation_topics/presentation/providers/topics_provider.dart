import 'package:flutter/foundation.dart';

import '../../data/models/topic_model.dart';
import '../../data/repositories/topics_repository.dart';

/// Quản lý trạng thái Kho chủ đề hội thoại (A1-B2), bộ lọc, tìm kiếm và tiến độ hoàn thành.
class TopicsProvider extends ChangeNotifier {
  TopicsProvider({TopicsRepository? repository})
      : _repository = repository ?? TopicsRepository();

  final TopicsRepository _repository;

  List<TopicModel> _topics = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedLevel = 'ALL';
  String _selectedCategory = 'ALL';
  String _searchQuery = '';
  bool _showOnlyIncomplete = false;
  String? _boundUserId;
  bool _hasLoadedInitial = false;
  bool _isDisposed = false;
  int _loadRequestSeq = 0;
  final Set<String> _updatingTopicIds = <String>{};

  List<TopicModel> get allTopics => List<TopicModel>.unmodifiable(_topics);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedLevel => _selectedLevel;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get showOnlyIncomplete => _showOnlyIncomplete;
  bool get hasActiveFilters =>
      _selectedLevel != 'ALL' ||
      _selectedCategory != 'ALL' ||
      _searchQuery.trim().isNotEmpty ||
      _showOnlyIncomplete;
  bool isUpdatingTopic(String topicId) => _updatingTopicIds.contains(topicId);

  int get totalCount => _topics.length;
  int get completedCount => _topics.where((t) => t.isCompleted).length;
  double get completionProgress =>
      totalCount == 0 ? 0.0 : completedCount / totalCount;

  /// Danh sách danh mục duy nhất (đã sắp xếp ổn định) để hiển thị bộ lọc phụ
  List<String> get availableCategories {
    final set = <String>{};
    for (final topic in _topics) {
      if (topic.category.trim().isNotEmpty) {
        set.add(topic.category.trim());
      }
    }
    final sorted = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['ALL', ...sorted];
  }

  /// Danh sách chủ đề sau khi áp dụng bộ lọc cấp độ (A1-B2), danh mục và từ khóa tìm kiếm
  List<TopicModel> get filteredTopics {
    final keyword = _searchQuery.trim().toLowerCase();

    return _topics.where((topic) {
      if (_selectedLevel != 'ALL' &&
          topic.level.toUpperCase() != _selectedLevel) {
        return false;
      }

      if (_selectedCategory != 'ALL' &&
          topic.category.trim().toLowerCase() !=
              _selectedCategory.toLowerCase()) {
        return false;
      }

      if (_showOnlyIncomplete && topic.isCompleted) {
        return false;
      }

      if (keyword.isNotEmpty) {
        final matchTitleVi = topic.title.toLowerCase().contains(keyword);
        final matchTitleEn = topic.titleEn.toLowerCase().contains(keyword);
        final matchDescVi = topic.description.toLowerCase().contains(keyword);
        final matchDescEn = topic.descriptionEn.toLowerCase().contains(keyword);
        final matchCategory = topic.category.toLowerCase().contains(keyword);
        if (!matchTitleVi &&
            !matchTitleEn &&
            !matchDescVi &&
            !matchDescEn &&
            !matchCategory) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  int countByLevel(String level) {
    final normalized = level.trim().toUpperCase();
    if (normalized.isEmpty || normalized == 'ALL') return _topics.length;
    return _topics
        .where((topic) => topic.level.trim().toUpperCase() == normalized)
        .length;
  }

  TopicModel? findById(String topicId) {
    for (final topic in _topics) {
      if (topic.id == topicId) return topic;
    }
    return null;
  }

  /// Tải danh sách chủ đề và đồng bộ tiến độ của [userId].
  Future<void> loadTopics({
    String? userId,
    bool forceRefresh = false,
  }) async {
    final normalizedUid =
        (userId != null && userId.trim().isNotEmpty) ? userId.trim() : null;

    if (_hasLoadedInitial &&
        !forceRefresh &&
        normalizedUid == _boundUserId &&
        _topics.isNotEmpty) {
      return;
    }

    final requestId = ++_loadRequestSeq;
    _boundUserId = normalizedUid;
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final fetched = await _repository.fetchTopics(userId: _boundUserId);
      if (_isDisposed || requestId != _loadRequestSeq) return;
      _topics = fetched;
      _hasLoadedInitial = true;
    } catch (e) {
      if (_isDisposed || requestId != _loadRequestSeq) return;
      _errorMessage = 'Không thể tải danh sách chủ đề. Vui lòng thử lại.';
      debugPrint('[TopicsProvider] Lỗi loadTopics: $e');
    } finally {
      if (!_isDisposed && requestId == _loadRequestSeq) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  void setLevelFilter(String level) {
    final candidate = level.trim().toUpperCase();
    final normalized = (candidate == 'ALL' ||
            TopicModel.supportedLevels.contains(candidate))
        ? candidate
        : 'ALL';
    if (_selectedLevel == normalized) return;
    _selectedLevel = normalized;
    _safeNotifyListeners();
  }

  void setCategoryFilter(String category) {
    final trimmed = category.trim();
    final normalized =
        (trimmed.isEmpty || trimmed.toUpperCase() == 'ALL') ? 'ALL' : trimmed;
    if (_selectedCategory.toLowerCase() == normalized.toLowerCase()) return;
    _selectedCategory = normalized;
    _safeNotifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _safeNotifyListeners();
  }

  void setShowOnlyIncomplete(bool value) {
    if (_showOnlyIncomplete == value) return;
    _showOnlyIncomplete = value;
    _safeNotifyListeners();
  }

  void resetFilters() {
    _selectedLevel = 'ALL';
    _selectedCategory = 'ALL';
    _searchQuery = '';
    _showOnlyIncomplete = false;
    _safeNotifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  /// Đổi trạng thái hoàn thành của một chủ đề (Optimistic UI + lưu Supabase).
  Future<bool> toggleTopicCompleted(
    String topicId, {
    String? userId,
  }) async {
    final index = _topics.indexWhere((t) => t.id == topicId);
    if (index == -1) return false;

    final previousTopic = _topics[index];
    if (_updatingTopicIds.contains(topicId)) {
      return previousTopic.isCompleted;
    }

    final nextCompleted = !previousTopic.isCompleted;

    // Optimistic UI update + guard against concurrent taps on the same topic
    _updatingTopicIds.add(topicId);
    final updatedList = List<TopicModel>.from(_topics);
    updatedList[index] = previousTopic.copyWith(isCompleted: nextCompleted);
    _topics = updatedList;
    _errorMessage = null;
    _safeNotifyListeners();

    final effectiveUid = userId ?? _boundUserId;
    if (effectiveUid == null || effectiveUid.trim().isEmpty) {
      _updatingTopicIds.remove(topicId);
      _safeNotifyListeners();
      return nextCompleted;
    }

    try {
      await _repository.setTopicCompleted(
        userId: effectiveUid,
        topicId: topicId,
        isCompleted: nextCompleted,
        topic: previousTopic,
      );
      return nextCompleted;
    } catch (e) {
      // Lookup current index by topicId in case _topics changed while awaiting
      final currentIndex = _topics.indexWhere((t) => t.id == topicId);
      if (currentIndex != -1) {
        final revertedList = List<TopicModel>.from(_topics);
        revertedList[currentIndex] = _topics[currentIndex].copyWith(
          isCompleted: previousTopic.isCompleted,
        );
        _topics = revertedList;
      }
      _errorMessage = 'Không thể lưu tiến độ chủ đề lên đám mây.';
      debugPrint('[TopicsProvider] Lỗi toggleTopicCompleted: $e');
      return previousTopic.isCompleted;
    } finally {
      _updatingTopicIds.remove(topicId);
      _safeNotifyListeners();
    }
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

