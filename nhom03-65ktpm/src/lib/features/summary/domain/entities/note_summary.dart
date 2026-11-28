import 'package:equatable/equatable.dart';

import 'summary_mode.dart';

/// Kết quả tóm tắt một ghi chú — Dart thuần, không phụ thuộc Flutter/HTTP.
///
/// Không ghi đè `Note.content`: bản tóm tắt là dữ liệu riêng, khớp bảng
/// `summaries` của Supabase.
class NoteSummary extends Equatable {
  const NoteSummary({
    required this.noteId,
    required this.mode,
    required this.content,
    required this.createdAt,
    this.model,
  });

  final String noteId;
  final SummaryMode mode;
  final String content;
  final DateTime createdAt;

  /// Tên model máy chủ báo về (ví dụ `gemini-2.5-flash`); có thể `null`.
  final String? model;

  /// Số từ ước tính để hiển thị cạnh kết quả.
  int get wordCount {
    return content
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .length;
  }

  @override
  List<Object?> get props => <Object?>[noteId, mode, content, createdAt, model];
}
