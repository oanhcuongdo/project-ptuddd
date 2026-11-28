/// Lỗi nghiệp vụ được trả từ tầng `data` lên `presentation`.
///
/// Tầng `domain` không phụ thuộc Flutter/Drift/Firebase, nên mọi exception của
/// hạ tầng phải được chuyển thành [Failure] trước khi đi ra ngoài.
sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Lỗi đọc/ghi cơ sở dữ liệu cục bộ (Drift).
final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// Lỗi dữ liệu không hợp lệ do người dùng nhập.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Lỗi xác thực (Firebase Auth).
///
/// [code] giữ mã lỗi gốc của Firebase để phân biệt lỗi mạng với lỗi sai thông
/// tin đăng nhập; [message] đã được dịch sang tiếng Việt để hiển thị thẳng lên
/// UI.
final class AuthFailure extends Failure {
  const AuthFailure(super.message, {this.code});

  final String? code;

  /// Mất mạng hoặc máy chủ không phản hồi trong lúc đăng nhập.
  bool get isNetworkError =>
      code == 'network-request-failed' ||
      code == 'unavailable' ||
      code == 'timeout';
}

/// Lỗi không xác định.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

/// Nhóm lỗi khi gọi máy chủ tóm tắt hoặc trắc nghiệm AI (#12, #13).
///
/// Tách khỏi [message] để UI quyết định hiển thị nút "Thử lại" hay hướng dẫn
/// cấu hình, thay vì phải so khớp chuỗi tiếng Việt.
enum AiFailureKind {
  /// Chưa truyền `--dart-define=AI_SUMMARY_ENDPOINT`.
  notConfigured,

  /// Không kết nối được máy chủ (mất mạng, DNS, TLS).
  network,

  /// Máy chủ không phản hồi trong thời gian cho phép.
  timeout,

  /// Hết lượt gọi API (HTTP 429).
  quotaExceeded,

  /// Token đăng nhập thiếu hoặc hết hạn (HTTP 401/403).
  unauthorized,

  /// Máy chủ lỗi (HTTP 5xx).
  server,

  /// Phản hồi không đúng định dạng hoặc rỗng.
  badResponse,

  /// Ghi chú không có nội dung để tóm tắt.
  emptyContent,
}

/// Lỗi tóm tắt AI đã dịch sang tiếng Việt để hiển thị thẳng lên UI.
final class AiFailure extends Failure {
  const AiFailure(super.message, {required this.kind});

  final AiFailureKind kind;

  /// Mất mạng hoặc quá thời gian chờ — UI nên gợi ý kiểm tra kết nối.
  bool get isNetworkError =>
      kind == AiFailureKind.network || kind == AiFailureKind.timeout;
}
