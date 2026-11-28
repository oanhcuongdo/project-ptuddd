import '../domain/entities/user_profile.dart';

/// Hợp đồng lập lịch nhắc ghi bữa.
///
/// Phân hệ Hồ sơ chỉ cần biết hợp đồng này. Phân hệ Thử thách & Nhắc nhở
/// (Issue #10) sẽ đăng ký bản cài đặt thật bằng flutter_local_notifications
/// trong DI; trước đó dùng [NoopReminderScheduler].
abstract class ReminderScheduler {
  /// Xin quyền gửi thông báo (Android 13+). Trả về true nếu được cấp.
  Future<bool> requestPermission();

  /// Hủy toàn bộ lịch cũ và lập lại theo [settings].
  Future<void> reschedule(ReminderSettings settings);

  /// Hủy toàn bộ lịch nhắc (khi đăng xuất).
  Future<void> cancelAll();
}

/// Bản rỗng, dùng khi chưa có phân hệ thông báo.
class NoopReminderScheduler implements ReminderScheduler {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> reschedule(ReminderSettings settings) async {}

  @override
  Future<void> cancelAll() async {}
}
