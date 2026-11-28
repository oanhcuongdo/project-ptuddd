import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/note.dart';
import '../../models/note_remote_mapper.dart';
import 'notes_remote_data_source.dart';

/// Đọc/ghi bảng `notes` qua Supabase (REST + Realtime).
///
/// Client được cấu hình `accessToken` là ID token Firebase (xem
/// `core/services/supabase_bootstrap.dart`), nên RLS chạy dưới đúng người
/// dùng và `.eq('user_id', …)` chỉ là lớp lọc phụ cho rõ nghĩa.
class SupabaseNotesRemoteDataSource implements NotesRemoteDataSource {
  SupabaseNotesRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Note>> fetchNotes(String userId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from(kNotesTable)
        .select()
        .eq('user_id', userId);
    return rows.map(noteFromRemoteRow).toList();
  }

  @override
  Stream<List<Note>> watchNotes(String userId) {
    return _client
        .from(kNotesTable)
        .stream(primaryKey: <String>['id'])
        .eq('user_id', userId)
        .map(
          (List<Map<String, dynamic>> rows) =>
              rows.map(noteFromRemoteRow).toList(),
        );
  }

  @override
  Future<void> upsertNote(String userId, Note note) async {
    await _client.rpc<void>(
      'save_note_revision',
      params: {'p_note': noteToRemoteJson(userId: userId, note: note)},
    );
  }
}
