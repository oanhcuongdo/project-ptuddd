import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thời điểm nhắc đầu tiên: hôm nay lúc [hour]:[minute] nếu chưa qua giờ và
/// người học chưa luyện, ngược lại là cùng giờ ngày mai.
DateTime nextReminderTime(DateTime now, int hour, int minute, {required bool practicedToday}) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  return practicedToday || !today.isAfter(now)
      ? DateTime(now.year, now.month, now.day + 1, hour, minute)
      : today;
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _reminderId = 1;
  static const _repeatId = 2;
  static const _title = 'Đến giờ luyện phát âm rồi! 🎤';
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'Nhắc luyện tập',
      channelDescription: 'Nhắc nhở luyện phát âm hằng ngày',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    if (kIsWeb) return; // web demo: notifications are Android/iOS only
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  static Future<void> requestPermission() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Đặt lần nhắc tiếp theo với nội dung streak mới nhất, kèm một thông báo lặp
  /// hằng ngày (nội dung chung) từ ngày hôm sau, để thông báo bị bỏ qua không
  /// lặp mãi số streak cũ.
  // shortcut: converts to a fixed UTC time, so the reminder shifts by an hour
  // across DST changes; add flutter_timezone and use tz.local if that matters.
  static Future<void> scheduleDaily(int hour, int minute, int streak,
      {bool practicedToday = false}) async {
    if (kIsWeb) return;
    await cancel();
    final first = nextReminderTime(DateTime.now(), hour, minute, practicedToday: practicedToday);
    tz.TZDateTime utc(DateTime d) => tz.TZDateTime.from(d.toUtc(), tz.UTC);
    await _plugin.zonedSchedule(
      id: _reminderId,
      title: _title,
      body: streak > 0
          ? 'Giữ chuỗi $streak ngày của bạn — chỉ cần vài phút hôm nay.'
          : 'Bắt đầu chuỗi ngày luyện tập mới ngay hôm nay.',
      scheduledDate: utc(first),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    await _plugin.zonedSchedule(
      id: _repeatId,
      title: _title,
      body: 'Vài phút luyện phát âm hôm nay giúp bạn giữ nhịp học.',
      scheduledDate: utc(DateTime(first.year, first.month, first.day + 1, hour, minute)),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel() async {
    if (kIsWeb) return;
    await _plugin.cancel(id: _reminderId);
    await _plugin.cancel(id: _repeatId);
  }

  /// Shows a foreground FCM notification while preserving the daily reminder.
  static Future<void> showMessage(String title, String body) async {
    if (kIsWeb) return;
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'group_updates',
          'Group updates',
          channelDescription: 'Study group submissions and comments',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
