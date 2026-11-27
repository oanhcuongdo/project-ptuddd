import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/database_tables.dart';
import '../../../../core/network/supabase_config.dart';
import '../models/vocab_entry_model.dart';

/// Repository quản lý truy vấn và thao tác dữ liệu bảng `public.vocab_notebook` trên Supabase.
class VocabRepository {
  final SupabaseClient? _clientOverride;

  VocabRepository({SupabaseClient? client}) : _clientOverride = client;

  SupabaseClient get _client => _clientOverride ?? SupabaseConfig.client;

  /// Kiểm tra kết nối Supabase đã sẵn sàng hay chưa
  bool get isReady =>
      _clientOverride != null ||
      (SupabaseConfig.isConfigured && SupabaseConfig.isInitialized);

  /// Tải toàn bộ danh sách từ vựng của người dùng [userId], sắp xếp mới nhất lên đầu
  Future<List<VocabEntryModel>> fetchUserVocab(String userId) async {
    if (!isReady || userId.trim().isEmpty) return const [];

    final rows = await _client
        .from(DatabaseTables.vocabNotebook)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows
        .map<VocabEntryModel>((row) => VocabEntryModel.fromMap(row))
        .toList();
  }

  /// Tìm từ vựng đã tồn tại trong sổ tay để tránh lưu trùng lặp
  Future<VocabEntryModel?> findExistingWord({
    required String userId,
    required String word,
    String sourceLang = 'en',
    String targetLang = 'vi',
  }) async {
    final normalizedWord = word.trim().toLowerCase();
    if (!isReady || userId.trim().isEmpty || normalizedWord.isEmpty) {
      return null;
    }

    final rows = await _client
        .from(DatabaseTables.vocabNotebook)
        .select()
        .eq('user_id', userId)
        .eq('source_lang', sourceLang.trim().toLowerCase())
        .eq('target_lang', targetLang.trim().toLowerCase());

    for (final row in rows) {
      final entry = VocabEntryModel.fromMap(row);
      if (entry.word.toLowerCase() == normalizedWord) {
        return entry;
      }
    }
    return null;
  }

  /// Đếm tổng số từ người dùng đã đánh dấu thuộc (`is_mastered = true`)
  Future<int> countMasteredWords(String userId) async {
    if (!isReady || userId.trim().isEmpty) return 0;

    final rows = await _client
        .from(DatabaseTables.vocabNotebook)
        .select('id')
        .eq('user_id', userId)
        .eq('is_mastered', true);

    return rows.length;
  }
}
