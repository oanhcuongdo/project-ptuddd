import 'package:buddytalk/features/vocab_notebook/data/models/vocab_entry_model.dart';
import 'package:buddytalk/features/vocab_notebook/data/models/vocab_filter.dart';
import 'package:buddytalk/features/vocab_notebook/data/repositories/vocab_repository.dart';
import 'package:buddytalk/features/vocab_notebook/presentation/providers/vocab_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeVocabRepository extends VocabRepository {
  final List<VocabEntryModel> store = [];
  int _seq = 1;

  @override
  bool get isReady => true;

  @override
  Future<List<VocabEntryModel>> fetchUserVocab(String userId) async {
    return store.where((e) => e.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<VocabEntryModel?> findExistingWord({
    required String userId,
    required String word,
    String sourceLang = 'en',
    String targetLang = 'vi',
  }) async {
    final lower = word.trim().toLowerCase();
    for (final entry in store) {
      if (entry.userId == userId &&
          entry.word.toLowerCase() == lower &&
          entry.sourceLang.toLowerCase() == sourceLang.toLowerCase() &&
          entry.targetLang.toLowerCase() == targetLang.toLowerCase()) {
        return entry;
      }
    }
    return null;
  }

  @override
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
    final existing = await findExistingWord(
      userId: userId,
      word: word,
      sourceLang: sourceLang,
      targetLang: targetLang,
    );
    if (existing != null && updateIfExists) {
      final updated = existing.copyWith(
        translatedMeaning: translatedMeaning,
        exampleSentence:
            exampleSentence.isNotEmpty ? exampleSentence : existing.exampleSentence,
      );
      return updateEntry(updated);
    }

    final created = VocabEntryModel(
      id: 'vocab_${_seq++}',
      userId: userId,
      word: word.trim(),
      translatedMeaning: translatedMeaning.trim(),
      sourceLang: sourceLang,
      targetLang: targetLang,
      exampleSentence: exampleSentence.trim(),
      isMastered: isMastered,
      createdAt: DateTime(2026, 11, 27, 10, _seq),
    );
    store.add(created);
    return created;
  }

  @override
  Future<VocabEntryModel> updateEntry(VocabEntryModel entry) async {
    final idx = store.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      store[idx] = entry;
    }
    return entry;
  }

  @override
  Future<VocabEntryModel> toggleMastered({
    required String entryId,
    required bool isMastered,
  }) async {
    final idx = store.indexWhere((e) => e.id == entryId);
    final updated = store[idx].copyWith(isMastered: isMastered);
    store[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    store.removeWhere((e) => e.id == entryId);
  }
}

void main() {
  group('VocabEntryModel', () {
    test('fromMap va toInsertMap anh xa dung cac cot Supabase vocab_notebook', () {
      final entry = VocabEntryModel.fromMap({
        'id': 'uuid-1',
        'user_id': 'user-1',
        'word': '  confidence  ',
        'translated_meaning': 'sự tự tin',
        'source_lang': 'en',
        'target_lang': 'vi',
        'example_sentence': 'Speak with confidence.',
        'is_mastered': false,
        'created_at': '2026-11-27T10:00:00.000Z',
      });

      expect(entry.word, 'confidence');
      expect(entry.hasExample, isTrue);
      expect(entry.languagePairLabel, 'EN → VI');
      expect(entry.dedupeKey, 'en->vi:confidence');

      final insertMap = entry.toInsertMap();
      expect(insertMap.containsKey('id'), isFalse);
      expect(insertMap['user_id'], 'user-1');
      expect(insertMap['word'], 'confidence');
      expect(insertMap['is_mastered'], isFalse);
    });
  });

  group('VocabFilter', () {
    final samples = [
      VocabEntryModel(
        id: '1',
        userId: 'u1',
        word: 'fluency',
        translatedMeaning: 'sự trôi chảy',
        sourceLang: 'en',
        targetLang: 'vi',
        exampleSentence: 'Improve speaking fluency',
        isMastered: true,
        createdAt: DateTime(2026, 11, 20),
      ),
      VocabEntryModel(
        id: '2',
        userId: 'u1',
        word: '你好',
        translatedMeaning: 'xin chào',
        sourceLang: 'zh-cn',
        targetLang: 'vi',
        exampleSentence: '',
        isMastered: false,
        createdAt: DateTime(2026, 11, 25),
      ),
      VocabEntryModel(
        id: '3',
        userId: 'u1',
        word: 'ambition',
        translatedMeaning: 'tham vọng',
        sourceLang: 'en',
        targetLang: 'vi',
        isMastered: false,
        createdAt: DateTime(2026, 11, 22),
      ),
    ];

    test('loc theo trang thai thuoc tu va ngon ngu chinh xac', () {
      const learningOnly = VocabFilter(masteryFilter: VocabMasteryFilter.learning);
      expect(learningOnly.apply(samples).map((e) => e.id).toList(), ['2', '3']);

      const zhFilter = VocabFilter(languageCode: 'zh');
      expect(zhFilter.apply(samples).map((e) => e.id).toList(), ['2']);

      const searchExample = VocabFilter(searchQuery: 'speaking');
      expect(searchExample.apply(samples).map((e) => e.id).toList(), ['1']);
    });

    test('sap xep theo moi nhat, cu nhat va A -> Z', () {
      const alpha = VocabFilter(sortOrder: VocabSortOrder.alphabetical);
      expect(alpha.apply(samples).map((e) => e.word).toList(), [
        'ambition',
        'fluency',
        '你好',
      ]);

      const oldest = VocabFilter(sortOrder: VocabSortOrder.oldest);
      expect(oldest.apply(samples).map((e) => e.id).toList(), ['1', '3', '2']);
    });
  });

  group('VocabProvider', () {
    late _FakeVocabRepository repo;
    late VocabProvider provider;

    setUp(() {
      repo = _FakeVocabRepository();
      provider = VocabProvider(repository: repo);
    });

    test('them tu moi, chong trung lap, toggleMastered va xoa tu hoat dong dung', () async {
      provider.bindUser('user-hai');
      await provider.refresh();
      expect(provider.totalCount, 0);

      final first = await provider.addOrUpdateWord(
        word: 'discipline',
        translatedMeaning: 'kỷ luật',
        sourceLang: 'en',
        targetLang: 'vi',
      );
      expect(first, isNotNull);
      expect(provider.totalCount, 1);
      expect(provider.masteredCount, 0);

      // Thêm trùng từ -> cập nhật lại bản ghi cũ, không tăng totalCount
      await provider.addOrUpdateWord(
        word: 'Discipline',
        translatedMeaning: 'tính kỷ luật',
        exampleSentence: 'Daily discipline builds fluency.',
      );
      expect(provider.totalCount, 1);
      expect(provider.allEntries.first.translatedMeaning, 'tính kỷ luật');

      await provider.toggleMastered(provider.allEntries.first);
      expect(provider.masteredCount, 1);
      expect(provider.masteryPercent, 100);

      await provider.deleteEntry(provider.allEntries.first.id);
      expect(provider.totalCount, 0);
    });
  });
}
