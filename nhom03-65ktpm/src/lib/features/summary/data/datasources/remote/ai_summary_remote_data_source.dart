import '../../../../../core/services/ai_client.dart';
import '../../../domain/entities/summary_mode.dart';

/// Nguồn gọi máy chủ tóm tắt — tách interface để test không cần mạng.
abstract interface class AiSummaryRemoteDataSource {
  Future<String> requestSummary({
    required String noteId,
    required String title,
    required String text,
    required SummaryMode mode,
  });
}

/// Gọi [AiClient] (HTTP) và trả về đúng chuỗi tóm tắt.
///
/// API key nằm ở máy chủ; app chỉ gửi nội dung ghi chú và token đăng nhập.
class AiSummaryRemoteDataSourceImpl implements AiSummaryRemoteDataSource {
  const AiSummaryRemoteDataSourceImpl(this._client);

  final AiClient _client;

  @override
  Future<String> requestSummary({
    required String noteId,
    required String title,
    required String text,
    required SummaryMode mode,
  }) {
    return _client.summarize(
      text: text,
      mode: mode.apiValue,
      noteId: noteId,
      title: title,
    );
  }
}
