import '../../../../core/error/failure.dart';
import '../entities/note_summary.dart';
import '../entities/summary_mode.dart';
import '../repositories/summary_repository.dart';

/// Use case tóm tắt một ghi chú theo kiểu người dùng chọn.
///
/// Kiểm tra nội dung rỗng ở đây để UI nhận thông báo rõ ràng mà không cần gọi
/// máy chủ.
class SummarizeNote {
  const SummarizeNote(this._repository);

  final SummaryRepository _repository;

  Future<NoteSummary> call({
    required String noteId,
    required String title,
    required String content,
    required SummaryMode mode,
  }) {
    if (content.trim().isEmpty) {
      throw const AiFailure(
        'Ghi chú chưa có nội dung để tóm tắt.',
        kind: AiFailureKind.emptyContent,
      );
    }
    return _repository.summarize(
      noteId: noteId,
      title: title,
      content: content,
      mode: mode,
    );
  }
}
