import 'package:shared_preferences/shared_preferences.dart';
import '../../features/2_gamification_parent/domain/streak_calculator.dart';
import '../../shared/entities/child_profile.dart';

class ReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const ReminderSettings({
    this.enabled = true,
    this.hour = 19,
    this.minute = 0,
  });

  String get timeFormatted {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get statusText {
    if (!enabled) return 'Đã tắt nhắc nhở';
    return 'Đang hoạt động: $timeFormatted hằng ngày';
  }
}

class ReminderService {
  static const String _keyEnabled = 'daily_reminder_enabled';
  static const String _keyHour = 'daily_reminder_hour';
  static const String _keyMinute = 'daily_reminder_minute';

  /// Lấy cấu hình lịch nhắc nhở hằng ngày (mặc định 19:00)
  static Future<ReminderSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? true;
    final hour = prefs.getInt(_keyHour) ?? 19;
    final minute = prefs.getInt(_keyMinute) ?? 0;
    return ReminderSettings(enabled: enabled, hour: hour, minute: minute);
  }

  /// Lưu cấu hình lịch nhắc nhở
  static Future<void> saveSettings({
    required bool enabled,
    int hour = 19,
    int minute = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setInt(_keyHour, hour);
    await prefs.setInt(_keyMinute, minute);
  }

  /// Kiểm tra có hiển thị banner nhắc nhở in-app không:
  /// Điều kiện: Đang bật nhắc nhở, giờ hiện tại >= giờ hẹn (19:00) và bé chưa hoàn thành bài tập hôm nay
  static bool shouldShowInAppReminder({
    required ReminderSettings settings,
    required ChildProfile profile,
    DateTime? now,
  }) {
    if (!settings.enabled) return false;

    final currentTime = now ?? DateTime.now();

    // Chưa đến giờ nhắc
    if (currentTime.hour < settings.hour) return false;
    if (currentTime.hour == settings.hour && currentTime.minute < settings.minute) {
      return false;
    }

    // Đã học hôm nay rồi -> không cần nhắc nữa
    if (StreakCalculator.isCompletedToday(profile.lastCompletedDate, currentTime)) {
      return false;
    }

    return true;
  }
}
