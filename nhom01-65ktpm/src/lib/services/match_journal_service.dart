import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/match_journal.dart';

/// CRUD bảng `match_journals`. Ảnh lưu URL vào cột `image_url` có sẵn.
class MatchJournalService {
  final SupabaseClient _client;

  MatchJournalService({SupabaseClient? client}) : _client = client ?? supabase;

  Future<List<MatchJournal>> listMine(String userId) async {
    final rows = await _client
        .from('match_journals')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    return (rows as List)
        .map((row) => MatchJournal.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<MatchJournal> save(MatchJournal journal) async {
    if (journal.id == null) {
      final row = await _client
          .from('match_journals')
          .insert(journal.toJson())
          .select()
          .single();
      return MatchJournal.fromJson(row);
    }
    final row = await _client
        .from('match_journals')
        .update(journal.toJson())
        .eq('id', journal.id!)
        .select()
        .single();
    return MatchJournal.fromJson(row);
  }

  Future<void> delete(int id) async {
    await _client.from('match_journals').delete().eq('id', id);
  }

  /// Upload ảnh sân bóng theo đặc tả BACKEND_AUTH_SPEC.md:
  /// Bucket: 'match_photos' (Public), cấu trúc: `<user_id>/match_<timestamp>.<ext>`
  /// Nếu bucket 'match_photos' chưa được tạo trên Supabase, fallback sang 'avatars'.
  Future<String> uploadPhoto({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final ext = fileExtension.replaceAll('.', '').toLowerCase();
    final path = '$userId/match_${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await _client.storage.from('match_photos').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );
      return _client.storage.from('match_photos').getPublicUrl(path);
    } catch (_) {
      // Fallback sang bucket 'avatars' đã có sẵn trên CSDL
      await _client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );
      return _client.storage.from('avatars').getPublicUrl(path);
    }
  }
}
