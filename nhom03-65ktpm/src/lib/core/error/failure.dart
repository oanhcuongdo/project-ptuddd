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

/// Lỗi không xác định.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
