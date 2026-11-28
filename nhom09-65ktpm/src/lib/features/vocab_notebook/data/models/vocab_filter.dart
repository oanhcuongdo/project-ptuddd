import 'vocab_entry_model.dart';

/// Bộ lọc trạng thái thuộc từ vựng trong Sổ tay.
enum VocabMasteryFilter {
  all('Tất cả'),
  learning('Đang học'),
  mastered('Đã thuộc');

  final String label;
  const VocabMasteryFilter(this.label);
}

/// Thứ tự sắp xếp danh sách từ vựng.
enum VocabSortOrder {
  newest('Mới nhất'),
  oldest('Cũ nhất'),
  alphabetical('A → Z');

  final String label;
  const VocabSortOrder(this.label);
}

/// Đối tượng cấu hình và thực thi lọc / tìm kiếm / sắp xếp cho Sổ tay từ vựng.
class VocabFilter {
  final String searchQuery;
  final String? languageCode;
  final VocabMasteryFilter masteryFilter;
  final VocabSortOrder sortOrder;

  const VocabFilter({
    this.searchQuery = '',
    this.languageCode,
    this.masteryFilter = VocabMasteryFilter.all,
    this.sortOrder = VocabSortOrder.newest,
  });

  /// Kiểm tra người dùng có đang áp dụng bộ lọc/tìm kiếm nào hay không
  bool get hasActiveFilter =>
      searchQuery.trim().isNotEmpty ||
      (languageCode != null && languageCode!.isNotEmpty) ||
      masteryFilter != VocabMasteryFilter.all;

  VocabFilter copyWith({
    String? searchQuery,
    String? languageCode,
    bool clearLanguage = false,
    VocabMasteryFilter? masteryFilter,
    VocabSortOrder? sortOrder,
  }) {
    return VocabFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      languageCode: clearLanguage ? null : (languageCode ?? this.languageCode),
      masteryFilter: masteryFilter ?? this.masteryFilter,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Đặt lại toàn bộ bộ lọc về mặc định
  VocabFilter reset() => const VocabFilter();

  /// Áp dụng lọc và sắp xếp lên danh sách từ vựng (trả về danh sách mới, không sửa list gốc)
  List<VocabEntryModel> apply(List<VocabEntryModel> entries) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final normalizedLangFilter = _normalizeLang(languageCode);

    final filtered = entries.where((entry) {
      if (masteryFilter == VocabMasteryFilter.learning && entry.isMastered) {
        return false;
      }
      if (masteryFilter == VocabMasteryFilter.mastered && !entry.isMastered) {
        return false;
      }

      if (normalizedLangFilter != null && normalizedLangFilter.isNotEmpty) {
        final entrySource = _normalizeLang(entry.sourceLang);
        if (entrySource != normalizedLangFilter) {
          return false;
        }
      }

      if (normalizedQuery.isNotEmpty) {
        final matchesWord = entry.word.toLowerCase().contains(normalizedQuery);
        final matchesMeaning =
            entry.translatedMeaning.toLowerCase().contains(normalizedQuery);
        final matchesExample =
            entry.exampleSentence.toLowerCase().contains(normalizedQuery);
        if (!matchesWord && !matchesMeaning && !matchesExample) {
          return false;
        }
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (sortOrder) {
        case VocabSortOrder.newest:
          return b.createdAt.compareTo(a.createdAt);
        case VocabSortOrder.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case VocabSortOrder.alphabetical:
          return a.word.toLowerCase().compareTo(b.word.toLowerCase());
      }
    });

    return filtered;
  }

  static String? _normalizeLang(String? rawCode) {
    if (rawCode == null) return null;
    final clean = rawCode.trim().toLowerCase().replaceAll('_', '-');
    if (clean.isEmpty || clean == 'all') return null;
    if (clean.startsWith('zh')) return 'zh-cn';
    if (clean.startsWith('en')) return 'en';
    if (clean.startsWith('vi')) return 'vi';
    return clean;
  }
}
