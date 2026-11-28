import 'dart:async';

/// Trạng thái đồng bộ hiển thị cho người dùng — tiêu chí 3 của #21.
enum SyncStatus {
  /// Chưa cấu hình Supabase (thiếu `--dart-define`): app chỉ lưu trên máy.
  disabled,

  /// Đang gửi/nhận thay đổi.
  syncing,

  /// Mọi thay đổi đã lên máy chủ.
  synced,

  /// Lần đồng bộ gần nhất thất bại (mất mạng, token hết hạn, RLS từ chối…).
  error,
}

/// Nơi duy nhất phát [SyncStatus] từ tầng `data` lên `presentation`.
///
/// Tầng ghi dữ liệu (repository) báo trạng thái, UI chỉ nghe — không tự đoán.
class SyncMonitor {
  SyncMonitor({SyncStatus initial = SyncStatus.disabled}) : _status = initial;

  final StreamController<SyncStatus> _controller =
      StreamController<SyncStatus>.broadcast();

  SyncStatus _status;

  SyncStatus get status => _status;

  /// Chỉ phát khi trạng thái **đổi**, tránh rebuild vô ích.
  Stream<SyncStatus> get stream => _controller.stream;

  void report(SyncStatus status, {String? message}) {
    _lastMessage = message;
    if (status == _status) {
      return;
    }
    _status = status;
    if (!_controller.isClosed) {
      _controller.add(status);
    }
  }

  String? _lastMessage;

  /// Thông điệp lỗi gần nhất (dùng cho tooltip của chỉ báo).
  String? get lastMessage => _lastMessage;

  Future<void> dispose() => _controller.close();
}
