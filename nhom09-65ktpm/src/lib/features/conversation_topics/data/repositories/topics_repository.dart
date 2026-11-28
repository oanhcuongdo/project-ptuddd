import 'package:flutter/foundation.dart';

import '../../../../core/database/database_tables.dart';
import '../../../../core/network/supabase_config.dart';
import '../models/topic_model.dart';
import '../models/topic_progress_model.dart';
import '../seed/default_topics_data.dart';

/// Repository quản lý Kho chủ đề hội thoại (`conversation_topics`)
/// và Tiến độ hoàn thành của người dùng (`user_topic_progress`).
class TopicsRepository {
  bool get isReady => SupabaseConfig.isInitialized;

  /// Tải danh sách chủ đề (A1-B2) kèm trạng thái hoàn thành của [userId].
  /// Nếu Supabase chưa cấu hình hoặc bảng chưa đủ dữ liệu kịch bản, tự động kết hợp
  /// dữ liệu mẫu từ [DefaultTopicsData] để đảm bảo trải nghiệm đầy đủ A1-B2.
  Future<List<TopicModel>> fetchTopics({String? userId}) async {
    final completedTopicIds = await _fetchCompletedTopicIds(userId);

    if (!isReady) {
      return _applyCompletionStatus(DefaultTopicsData.topics, completedTopicIds);
    }

    try {
      final rows = await SupabaseConfig.client
          .from(DatabaseTables.conversationTopics)
          .select()
          .order('level', ascending: true)
          .order('id', ascending: true);

      final defaultMap = DefaultTopicsData.byId;
      final mergedById = <String, TopicModel>{};

      for (final raw in rows) {
        final remote = TopicModel.fromMap(raw);
        final fallback = defaultMap[remote.id];

        // Fill in curated starters/dialogues if the remote seed row only has metadata
        final enriched = remote.copyWith(
          descriptionEn: remote.descriptionEn.isNotEmpty
              ? remote.descriptionEn
              : (fallback?.descriptionEn ?? ''),
          conversationStarters: remote.conversationStarters.isNotEmpty
              ? remote.conversationStarters
              : (fallback?.conversationStarters ?? const []),
          sampleDialogues: remote.sampleDialogues.isNotEmpty
              ? remote.sampleDialogues
              : (fallback?.sampleDialogues ?? const []),
          isCompleted: completedTopicIds.contains(remote.id),
        );
        mergedById[enriched.id] = enriched;
      }

      // Ensure all A1-B2 default topics are present even if DB only seeded A1-A2
      for (final fallback in DefaultTopicsData.topics) {
        mergedById.putIfAbsent(
          fallback.id,
          () => fallback.copyWith(
            isCompleted: completedTopicIds.contains(fallback.id),
          ),
        );
      }

      final result = mergedById.values.toList()
        ..sort((a, b) {
          final levelCompare = _levelRank(a.level).compareTo(_levelRank(b.level));
          if (levelCompare != 0) return levelCompare;
          return a.id.compareTo(b.id);
        });
      return result;
    } catch (e) {
      debugPrint('[TopicsRepository] Lỗi tải conversation_topics: $e');
      return _applyCompletionStatus(DefaultTopicsData.topics, completedTopicIds);
    }
  }

  /// Cập nhật trạng thái hoàn thành chủ đề vào bảng `user_topic_progress`.
  Future<void> setTopicCompleted({
    required String userId,
    required String topicId,
    required bool isCompleted,
  }) async {
    if (!isReady || userId.trim().isEmpty || topicId.trim().isEmpty) return;

    final progress = TopicProgressModel(
      userId: userId,
      topicId: topicId,
      isCompleted: isCompleted,
      completedAt: DateTime.now(),
    );

    await SupabaseConfig.client
        .from(DatabaseTables.userTopicProgress)
        .upsert(progress.toMap(), onConflict: 'user_id,topic_id');
  }

  Future<Set<String>> _fetchCompletedTopicIds(String? userId) async {
    if (!isReady || userId == null || userId.trim().isEmpty) {
      return <String>{};
    }

    try {
      final rows = await SupabaseConfig.client
          .from(DatabaseTables.userTopicProgress)
          .select('topic_id, is_completed')
          .eq('user_id', userId)
          .eq('is_completed', true);

      return rows
          .map<String>((row) => (row['topic_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('[TopicsRepository] Lỗi tải user_topic_progress: $e');
      return <String>{};
    }
  }

  List<TopicModel> _applyCompletionStatus(
    List<TopicModel> source,
    Set<String> completedIds,
  ) {
    return source
        .map((topic) =>
            topic.copyWith(isCompleted: completedIds.contains(topic.id)))
        .toList();
  }

  int _levelRank(String level) {
    final index = TopicModel.supportedLevels.indexOf(level.toUpperCase());
    return index == -1 ? 99 : index;
  }
}

