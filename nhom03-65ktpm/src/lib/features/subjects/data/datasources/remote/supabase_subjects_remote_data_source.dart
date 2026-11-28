import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/subject.dart';
import '../../models/subject_remote_mapper.dart';
import 'subjects_remote_data_source.dart';

/// Đọc/ghi bảng `subjects` qua Supabase.
///
/// Client đã gắn ID token Firebase, RLS chỉ cho đọc/ghi môn của chính người
/// dùng; `.eq('user_id', …)` chỉ là lớp lọc phụ cho rõ nghĩa.
class SupabaseSubjectsRemoteDataSource implements SubjectsRemoteDataSource {
  SupabaseSubjectsRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Subject>> fetchSubjects(String userId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from(kSubjectsTable)
        .select()
        .eq('user_id', userId);
    return rows.map(subjectFromRemoteRow).toList();
  }

  @override
  Future<void> upsertSubject(String userId, Subject subject) async {
    await _client
        .from(kSubjectsTable)
        .upsert(subjectToRemoteJson(userId: userId, subject: subject));
  }
}
