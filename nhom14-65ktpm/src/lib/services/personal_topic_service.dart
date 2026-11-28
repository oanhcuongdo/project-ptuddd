import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/personal_topic_model.dart';

class PersonalTopicService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập hệ thống');
    }
    return user.id;
  }

  // 0. Lấy danh sách lĩnh vực từ bảng fields để hiển thị trong Dropdown
  Future<List<FieldItem>> fetchFields() async {
    try {
      final response = await _supabase.from('fields').select();
      return (response as List)
          .map((json) => FieldItem.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 1. Lấy danh sách toàn bộ đề tài cá nhân (kèm tên lĩnh vực nếu có)
  Future<List<PersonalTopic>> fetchPersonalTopics() async {
    final response = await _supabase
        .from('personal_topics')
        .select(', fields()')
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => PersonalTopic.fromJson(json))
        .toList();
  }

  // 2. Thêm đề tài mới từ ý tưởng cá nhân (Tự nhập)
  Future<PersonalTopic> createTopic(PersonalTopic topic) async {
    final data = topic.toJson();
    data['user_id'] = _currentUserId;
    data['source'] = 'manual';

    final response = await _supabase
        .from('personal_topics')
        .insert(data)
        .select(', fields()')
        .single();

    return PersonalTopic.fromJson(response);
  }

  // 3. Lưu gợi ý từ AI (phối hợp với TV3) thành đề tài cá nhân
  Future<PersonalTopic> saveFromAiSuggestion({
    required String title,
    String? description,
    String? objectives,
    String? fieldId,
    String? technologies,
    String? implementationPlan,
  }) async {
    final data = {
      'user_id': _currentUserId,
      'field_id': fieldId,
      'title': title,
      'description': description,
      'objectives': objectives,
      'technologies': technologies,
      'implementation_plan': implementationPlan,
      'status': 'idea',
      'source': 'ai_suggestion',
    };

    final response = await _supabase
        .from('personal_topics')
        .insert(data)
        .select(', fields()')
        .single();

    return PersonalTopic.fromJson(response);
  }

  // 4. Chỉnh sửa thông tin hoặc cập nhật trạng thái đề tài
  Future<void> updateTopic(PersonalTopic topic) async {
    if (topic.id == null) return;
    await _supabase
        .from('personal_topics')
        .update(topic.toJson())
        .eq('id', topic.id!)
        .eq('user_id', _currentUserId);
  }

  // 5. Xóa đề tài cá nhân
  Future<void> deleteTopic(String topicId) async {
    await _supabase
        .from('personal_topics')
        .delete()
        .eq('id', topicId)
        .eq('user_id', _currentUserId);
  }
}
