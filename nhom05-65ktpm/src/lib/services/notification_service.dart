import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _reminderId = 1;
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails('daily_reminder', 'Nhắc luyện tập',
        channelDescription: 'Nhắc nhở luyện phát âm hằng ngày',
        importance: Importance.high,
        priority: Priority.high),
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
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules a daily reminder at local [hour]:[minute].
  // shortcut: converts to a fixed UTC time, so the reminder shifts by an hour
  // across DST changes; add flutter_timezone and use tz.local if that matters.
  static Future<void> scheduleDaily(int hour, int minute, int streak) async {
    if (kIsWeb) return;
    await cancel();
    final now = DateTime.now();
    var at = DateTime(now.year, now.month, now.day, hour, minute);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: _reminderId,
      title: 'Đến giờ luyện phát âm rồi! 🎤',
      body: streak > 0
          ? 'Giữ chuỗi $streak ngày của bạn — chỉ cần vài phút hôm nay.'
          : 'Bắt đầu chuỗi ngày luyện tập mới ngay hôm nay.',
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel() async {
    if (!kIsWeb) await _plugin.cancel(id: _reminderId);
  }
}
