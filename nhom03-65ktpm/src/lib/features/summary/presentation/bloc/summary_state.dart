import 'package:equatable/equatable.dart';

import '../../domain/entities/note_summary.dart';
import '../../domain/entities/summary_mode.dart';

/// Trạng thái màn tóm tắt AI.
enum SummaryStatus {
  /// Chưa gọi lần nào (hoặc vừa đổi kiểu tóm tắt).
  idle,
  loading,
  success,
  failure,

  /// Ghi chú không có nội dung để tóm tắt.
  empty,
}

const Object _unset = Object();

class SummaryState extends Equatable {
  const SummaryState({
    this.status = SummaryStatus.idle,
    this.mode = SummaryMode.short,
    this.result,
    this.errorMessage,
    this.isNetworkError = false,
    this.elapsed,
  });

  final SummaryStatus status;
  final SummaryMode mode;
  final NoteSummary? result;
  final String? errorMessage;

  /// Lỗi do mất mạng/quá giờ — UI gợi ý kiểm tra kết nối.
  final bool isNetworkError;

  /// Thời gian máy chủ trả kết quả, dùng để hiển thị "xong trong x,y giây".
  final Duration? elapsed;

  bool get isLoading => status == SummaryStatus.loading;

  SummaryState copyWith({
    SummaryStatus? status,
    SummaryMode? mode,
    Object? result = _unset,
    Object? errorMessage = _unset,
    bool? isNetworkError,
    Object? elapsed = _unset,
  }) {
    return SummaryState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      result: identical(result, _unset) ? this.result : result as NoteSummary?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      isNetworkError: isNetworkError ?? this.isNetworkError,
      elapsed: identical(elapsed, _unset) ? this.elapsed : elapsed as Duration?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    mode,
    result,
    errorMessage,
    isNetworkError,
    elapsed,
  ];
}
