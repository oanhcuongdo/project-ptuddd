import '../entities/note_summary.dart';
import '../entities/summary_mode.dart';

/// Cổng ra tầng dữ liệu cho tính năng tóm tắt AI (#12).
///
/// Nhận chuỗi thuần thay vì entity `Note` để feature `summary` không phải
/// import chéo `features/notes` (rules/AGENTS.md §9).
abstract interface class SummaryRepository {
  Future<NoteSummary> summarize({
    required String noteId,
    required String title,
    required String content,
    required SummaryMode mode,
  });
}
