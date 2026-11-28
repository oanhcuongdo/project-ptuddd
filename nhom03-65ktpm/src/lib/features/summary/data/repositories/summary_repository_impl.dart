import '../../../../core/error/failure.dart';
import '../../domain/entities/note_summary.dart';
import '../../domain/entities/summary_mode.dart';
import '../../domain/repositories/summary_repository.dart';
import '../datasources/remote/ai_summary_remote_data_source.dart';

/// Cài đặt [SummaryRepository]: gọi máy chủ rồi đóng gói thành [NoteSummary].
class SummaryRepositoryImpl implements SummaryRepository {
  const SummaryRepositoryImpl(this._remoteDataSource);

  final AiSummaryRemoteDataSource _remoteDataSource;

  @override
  Future<NoteSummary> summarize({
    required String noteId,
    required String title,
    required String content,
    required SummaryMode mode,
  }) async {
    try {
      final result = await _remoteDataSource.requestSummary(
        noteId: noteId,
        title: title,
        text: content,
        mode: mode,
      );
      final trimmed = result.trim();
      if (trimmed.isEmpty) {
        throw const AiFailure(
          'Máy chủ trả về kết quả rỗng. Thử lại sau.',
          kind: AiFailureKind.badResponse,
        );
      }
      return NoteSummary(
        noteId: noteId,
        mode: mode,
        content: trimmed,
        createdAt: DateTime.now(),
      );
    } on Failure {
      rethrow;
    } catch (error) {
      throw UnexpectedFailure('Không tóm tắt được ghi chú: $error');
    }
  }
}
