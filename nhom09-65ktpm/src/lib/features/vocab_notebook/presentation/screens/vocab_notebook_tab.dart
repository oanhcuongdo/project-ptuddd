import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/vocab_entry_model.dart';
import '../components/add_vocab_dialog.dart';
import '../components/vocab_filter_bar.dart';
import '../components/vocab_flashcard_dialog.dart';
import '../components/vocab_stats_header.dart';
import '../components/vocab_translator_box.dart';
import '../components/vocab_word_card.dart';
import '../providers/vocab_provider.dart';
import '../styles/vocab_styles.dart';

/// Màn hình chính của Phân hệ Sổ tay Từ vựng & Trợ lý Dịch thuật (Tab "Sổ tay" trên MainLayout).
/// Ghép nối đồng bộ: Thống kê tiến độ, Hộp tra cứu 3 thứ tiếng, Bộ lọc tìm kiếm, Danh sách thẻ từ và Ôn tập Flashcard.
class VocabNotebookTab extends StatefulWidget {
  const VocabNotebookTab({super.key});

  @override
  State<VocabNotebookTab> createState() => _VocabNotebookTabState();
}

class _VocabNotebookTabState extends State<VocabNotebookTab> {
  VocabProvider? _fallbackProvider;

  @override
  void dispose() {
    _fallbackProvider?.dispose();
    super.dispose();
  }

  /// Lấy `VocabProvider` từ cây Widget (an toàn cả khi chạy Widget Test cô lập không khai báo VocabProvider)
  VocabProvider _resolveProvider(BuildContext context) {
    try {
      return Provider.of<VocabProvider>(context);
    } on ProviderNotFoundException {
      return _fallbackProvider ??= VocabProvider();
    }
  }

  Future<void> _handleAddOrEdit(
    VocabProvider provider, {
    VocabEntryModel? existing,
  }) async {
    final result = await AddVocabDialog.show(context, existing: existing);
    if (!mounted || result == null) return;

    if (existing != null) {
      final ok = await provider.updateEntry(
        existing.copyWith(
          word: result.word,
          translatedMeaning: result.translatedMeaning,
          sourceLang: result.sourceLang,
          targetLang: result.targetLang,
          exampleSentence: result.exampleSentence,
        ),
      );
      if (!mounted) return;
      _showFeedback(
        ok ? 'Đã cập nhật từ "${result.word}".' : 'Cập nhật thất bại.',
        isError: !ok,
      );
      return;
    }

    final saved = await provider.addOrUpdateWord(
      word: result.word,
      translatedMeaning: result.translatedMeaning,
      sourceLang: result.sourceLang,
      targetLang: result.targetLang,
      exampleSentence: result.exampleSentence,
    );
    if (!mounted) return;
    _showFeedback(
      saved != null
          ? 'Đã lưu "${saved.word}" vào Sổ tay.'
          : (provider.errorMessage ?? 'Không thể lưu từ mới.'),
      isError: saved == null,
    );
  }

  Future<void> _handleDelete(
    VocabProvider provider,
    VocabEntryModel entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa từ vựng?'),
        content: Text(
          'Bạn có chắc muốn xóa "${entry.word}" khỏi Sổ tay từ vựng không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await provider.deleteEntry(entry.id);
    if (!mounted) return;
    _showFeedback(
      ok ? 'Đã xóa "${entry.word}".' : 'Không thể xóa từ vựng.',
      isError: !ok,
    );
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : VocabStyles.tealDark,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = _resolveProvider(context);

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final entries = provider.filteredEntries;

        return RefreshIndicator(
          color: VocabStyles.tealPrimary,
          onRefresh: () => provider.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VocabStatsHeader(
                      totalCount: provider.totalCount,
                      masteredCount: provider.masteredCount,
                      learningCount: provider.learningCount,
                      masteryPercent: provider.masteryPercent,
                      masteryProgress: provider.masteryProgress,
                      onStartFlashcard: () => VocabFlashcardDialog.show(
                        context,
                        entries: provider.flashcardEntries,
                        onToggleMastered: provider.toggleMastered,
                      ),
                      onAddWord: () => _handleAddOrEdit(provider),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    VocabTranslatorBox(
                      onSaveToNotebook: ({
                        required word,
                        required translatedMeaning,
                        required sourceLang,
                        required targetLang,
                      }) async {
                        final saved = await provider.addOrUpdateWord(
                          word: word,
                          translatedMeaning: translatedMeaning,
                          sourceLang: sourceLang,
                          targetLang: targetLang,
                        );
                        if (!mounted) return false;
                        _showFeedback(
                          saved != null
                              ? 'Đã lưu "${saved.word}" vào Sổ tay!'
                              : (provider.errorMessage ?? 'Không thể lưu từ.'),
                          isError: saved == null,
                        );
                        return saved != null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    VocabFilterBar(
                      filter: provider.filter,
                      resultCount: entries.length,
                      onSearchChanged: provider.setSearchQuery,
                      onLanguageChanged: provider.setLanguageFilter,
                      onMasteryChanged: provider.setMasteryFilter,
                      onSortChanged: provider.setSortOrder,
                      onReset: provider.resetFilters,
                    ),
                    if (provider.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildErrorBanner(provider),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (provider.isLoading && provider.allEntries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: VocabStyles.tealPrimary,
                          ),
                        ),
                      )
                    else if (entries.isEmpty)
                      _buildEmptyState(provider)
                    else
                      _buildWordGrid(provider, entries),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(VocabProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.errorMessage!,
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
          IconButton(
            onPressed: provider.clearError,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 17),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(VocabProvider provider) {
    final isFiltered = provider.filter.hasActiveFilter;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: VocabStyles.cardDecoration,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: VocabStyles.tealSoftBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: VocabStyles.tealBorder),
            ),
            child: Icon(
              isFiltered
                  ? Icons.search_off_rounded
                  : Icons.menu_book_rounded,
              size: 32,
              color: VocabStyles.tealPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isFiltered
                ? 'Không tìm thấy từ vựng phù hợp'
                : 'Sổ tay của bạn chưa có từ mới nào',
            textAlign: TextAlign.center,
            style: VocabStyles.sectionTitle,
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'Thử đổi từ khóa tìm kiếm hoặc đặt lại bộ lọc để xem toàn bộ từ đã lưu.'
                : 'Hãy dùng khung Tra cứu nhanh phía trên hoặc chạm vào từ mới trong Phòng học để lưu vào Sổ tay nhé!',
            textAlign: TextAlign.center,
            style: VocabStyles.metaText,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: isFiltered
                ? provider.resetFilters
                : () => _handleAddOrEdit(provider),
            style: FilledButton.styleFrom(
              backgroundColor: VocabStyles.tealPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              isFiltered ? Icons.filter_alt_off_rounded : Icons.add_rounded,
              size: 18,
            ),
            label: Text(isFiltered ? 'Đặt lại bộ lọc' : 'Thêm từ đầu tiên'),
          ),
        ],
      ),
    );
  }

  Widget _buildWordGrid(
    VocabProvider provider,
    List<VocabEntryModel> entries,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = constraints.maxWidth >= 760;
        if (!isTwoColumn) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, index) => _buildCard(provider, entries[index]),
          );
        }

        final itemWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: entries
              .map(
                (entry) => SizedBox(
                  width: itemWidth,
                  child: _buildCard(provider, entry),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildCard(VocabProvider provider, VocabEntryModel entry) {
    return VocabWordCard(
      entry: entry,
      onToggleMastered: () => provider.toggleMastered(entry),
      onEdit: () => _handleAddOrEdit(provider, existing: entry),
      onDelete: () => _handleDelete(provider, entry),
    );
  }
}
