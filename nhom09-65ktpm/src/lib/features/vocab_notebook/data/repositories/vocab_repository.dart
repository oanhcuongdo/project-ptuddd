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

  /// Thêm một từ vựng mới vào bảng `vocab_notebook`.
  /// Nếu từ đã tồn tại cùng cặp ngôn ngữ:
  /// - Nếu [updateIfExists] = true -> cập nhật lại nghĩa dịch & câu ví dụ mới nhất.
  /// - Nếu [updateIfExists] = false -> trả về bản ghi cũ để tránh trùng lặp.
  Future<VocabEntryModel> addVocabEntry({
    required String userId,
    required String word,
    required String translatedMeaning,
    String sourceLang = 'en',
    String targetLang = 'vi',
    String exampleSentence = '',
    bool isMastered = false,
    bool updateIfExists = true,
  }) async {
    final cleanWord = word.trim();
    final cleanMeaning = translatedMeaning.trim();
    if (cleanWord.isEmpty || cleanMeaning.isEmpty) {
      throw ArgumentError('Từ vựng và nghĩa dịch không được để trống.');
    }

    final existing = await findExistingWord(
      userId: userId,
      word: cleanWord,
      sourceLang: sourceLang,
      targetLang: targetLang,
    );

    if (existing != null) {
      if (!updateIfExists) return existing;
      final mergedExample = exampleSentence.trim().isNotEmpty
          ? exampleSentence.trim()
          : existing.exampleSentence;
      return updateEntry(
        existing.copyWith(
          translatedMeaning: cleanMeaning,
          exampleSentence: mergedExample,
        ),
      );
    }

    final draft = VocabEntryModel(
      id: '',
      userId: userId,
      word: cleanWord,
      translatedMeaning: cleanMeaning,
      sourceLang: sourceLang,
      targetLang: targetLang,
      exampleSentence: exampleSentence.trim(),
      isMastered: isMastered,
      createdAt: DateTime.now(),
    );

    final row = await _client
        .from(DatabaseTables.vocabNotebook)
        .insert(draft.toInsertMap())
        .select()
        .single();

    return VocabEntryModel.fromMap(row);
  }

  /// Cập nhật toàn bộ thông tin của một mục từ vựng đã có
  Future<VocabEntryModel> updateEntry(VocabEntryModel entry) async {
    final row = await _client
        .from(DatabaseTables.vocabNotebook)
        .update(entry.toUpdateMap())
        .eq('id', entry.id)
        .select()
        .single();

    return VocabEntryModel.fromMap(row);
  }

  /// Đánh dấu đã thuộc hoặc cần ôn lại (`is_mastered`) cho một từ vựng
  Future<VocabEntryModel> toggleMastered({
    required String entryId,
    required bool isMastered,
  }) async {
    final row = await _client
        .from(DatabaseTables.vocabNotebook)
        .update({'is_mastered': isMastered})
        .eq('id', entryId)
        .select()
        .single();

    return VocabEntryModel.fromMap(row);
  }

  /// Xóa một từ vựng khỏi Sổ tay trên Supabase
  Future<void> deleteEntry(String entryId) async {
    await _client
        .from(DatabaseTables.vocabNotebook)
        .delete()
        .eq('id', entryId);
  }
}
