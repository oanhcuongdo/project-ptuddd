/// Kiểu kết quả đơn giản để xử lý lỗi mà không phải ném exception lên UI.
///
/// Cách dùng:
/// ```dart
/// final result = await useCase(...);
/// switch (result) {
///   case Ok(:final value): ...      // thành công
///   case Err(:final failure): ...   // thất bại, hiển thị failure.message
/// }
/// ```
library;

/// Nhóm lỗi, dùng để UI chọn thông báo và hướng xử lý phù hợp.
enum FailureType {
  network,
  timeout,
  quotaExceeded,
  rateLimited,
  appCheck,
  permissionDenied,
  auth,
  invalidResponse,
  notRecognized,
  cancelled,
  unknown,
}

class AppFailure {
  const AppFailure(this.type, [this.message = '', this.cause]);

  final FailureType type;

  /// Thông điệp thân thiện (tiếng Việt) có thể hiển thị cho người dùng.
  final String message;

  /// Lỗi gốc (chỉ để debug, không hiển thị).
  final Object? cause;

  @override
  String toString() => 'AppFailure($type, $message, $cause)';
}

sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  /// Giá trị khi thành công, null khi thất bại.
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}
