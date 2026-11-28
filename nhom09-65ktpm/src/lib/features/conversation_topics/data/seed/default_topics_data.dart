import '../models/topic_model.dart';
import 'default_topics_beginner.dart';
import 'default_topics_intermediate.dart';

/// Kho dữ liệu kịch bản hội thoại & gợi ý câu mở đầu chuẩn theo 4 cấp độ CEFR (A1 - B2).
/// Dùng làm nguồn bổ sung cho các dòng seed cơ bản trên Supabase và fallback khi offline.
class DefaultTopicsData {
  DefaultTopicsData._();

  static final List<TopicModel> topics = [
    ...defaultBeginnerTopics,
    ...defaultIntermediateTopics,
  ];

  static Map<String, TopicModel> get byId => {
        for (final topic in topics) topic.id: topic,
      };

  /// Lọc nhanh danh sách chủ đề mẫu theo cấp độ CEFR (A1, A2, B1, B2).
  static List<TopicModel> byLevel(String level) {
    final normalized = level.trim().toUpperCase();
    if (normalized.isEmpty || normalized == 'ALL') {
      return List<TopicModel>.unmodifiable(topics);
    }
    return topics
        .where((topic) => topic.level.toUpperCase() == normalized)
        .toList();
  }
}
