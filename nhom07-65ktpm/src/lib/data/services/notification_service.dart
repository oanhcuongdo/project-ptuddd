import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isPermissionGranted = true;
  bool get isPermissionGranted => _isPermissionGranted;

  bool _tzInitialized = false;

  void _ensureTimezoneInitialized() {
    if (_tzInitialized) return;
    tz_data.initializeTimeZones();
    final localNow = DateTime.now();
    final localOffset = localNow.timeZoneOffset;
    final offsetMinutes = localOffset.inMinutes.abs();
    final localZoneName =
        'GMT${localOffset.isNegative ? '-' : '+'}'
        '${(offsetMinutes ~/ 60).toString().padLeft(2, '0')}:'
        '${(offsetMinutes % 60).toString().padLeft(2, '0')}';
    tz.setLocalLocation(
      tz.Location(localZoneName, [tz.minTime], [0], [
        tz.TimeZone(
          localOffset,
          isDst: false,
          abbreviation: localNow.timeZoneName,
        ),
      ]),
    );
    _tzInitialized = true;
  }

  Future<void> initialize() async {
    try {
      _ensureTimezoneInitialized();

      await _notificationsPlugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
          windows: WindowsInitializationSettings(
            appName: 'DCSleep',
            appUserModelId: 'com.nhom07.dcsleep',
            guid: '7f4c2b9e-6a1d-4c83-b5e0-2d9a8f31c647',
          ),
          web: WebInitializationSettings(),
        ),
      );
      debugPrint(
        '[NotificationService] Đã khởi tạo hệ thống thông báo cục bộ DCSleep.',
      );
    } catch (e) {
      debugPrint('[NotificationService] Lỗi khởi tạo thông báo cục bộ: $e');
      return;
    }
  }

  Future<bool> requestPermission() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        _isPermissionGranted =
            await androidPlugin?.requestNotificationsPermission() ?? false;
        await androidPlugin?.requestExactAlarmsPermission();
        return _isPermissionGranted;
      }

      _isPermissionGranted = true;
      return _isPermissionGranted;
    } catch (e) {
      debugPrint('[NotificationService] Lỗi xin quyền thông báo: $e');
      _isPermissionGranted = false;
      return false;
    }
  }

  Future<void> showNow({required String title, required String body}) async {
    try {
      final id = 1000 + DateTime.now().millisecondsSinceEpoch.remainder(1000000);
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'dcsleep_reminders',
            'Nhắc nhở giấc ngủ',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          windows: WindowsNotificationDetails(),
          web: WebNotificationDetails(),
        ),
      );
      debugPrint(
        '[NotificationService] Đã hiển thị thông báo tức thì: id=$id, title="$title", body="$body".',
      );
    } catch (e) {
      debugPrint('[NotificationService] Lỗi hiển thị thông báo: $e');
    }
  }

  Future<void> cancelBedtimeReminders() async {
    var cancelled = true;
    for (var id = 100; id <= 107; id++) {
      try {
        await _notificationsPlugin.cancel(id: id);
      } catch (e) {
        cancelled = false;
        debugPrint(
          '[NotificationService] Lỗi hủy lịch nhắc giờ đi ngủ id=$id: $e',
        );
      }
    }

    if (cancelled) {
      debugPrint(
        '[NotificationService] Đã hủy lịch nhắc giờ đi ngủ (id 100-107).',
      );
    }
  }

  Future<void> scheduleBedtimeReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
    String? activeDays,
  }) async {
    try {
      _ensureTimezoneInitialized();
      await cancelBedtimeReminders();

      const weekdayNumbers = <String, int>{
        'T2': DateTime.monday,
        'T3': DateTime.tuesday,
        'T4': DateTime.wednesday,
        'T5': DateTime.thursday,
        'T6': DateTime.friday,
        'T7': DateTime.saturday,
        'CN': DateTime.sunday,
      };
      final selectedDays = activeDays == null || activeDays.trim().isEmpty
          ? <int>{
              for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                day,
            }
          : activeDays
                .split(',')
                .map((day) => weekdayNumbers[day.trim().toUpperCase()])
                .whereType<int>()
                .toSet();

      if (selectedDays.isEmpty) {
        debugPrint(
          '[NotificationService] Không có ngày áp dụng hợp lệ; không lên lịch nhắc giờ đi ngủ.',
        );
        return;
      }

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'dcsleep_reminders',
          'Nhắc nhở giấc ngủ',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        windows: WindowsNotificationDetails(),
        web: WebNotificationDetails(),
      );

      final isWeeklyPlatform =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS);
      if (isWeeklyPlatform) {
        final now = tz.TZDateTime.now(tz.local);
        for (final weekday in selectedDays.toList()..sort()) {
          var daysUntil =
              (weekday - now.weekday + DateTime.daysPerWeek) %
              DateTime.daysPerWeek;
          var scheduledDate = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day + daysUntil,
            hour,
            minute,
          );
          if (!scheduledDate.isAfter(now)) {
            daysUntil += DateTime.daysPerWeek;
            scheduledDate = tz.TZDateTime(
              tz.local,
              now.year,
              now.month,
              now.day + daysUntil,
              hour,
              minute,
            );
          }

          await _notificationsPlugin.zonedSchedule(
            id: 100 + weekday,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
          debugPrint(
            '[NotificationService] Đã lên lịch lặp ${_weekdayName(weekday)} '
            'lúc ${_formatTime(hour, minute)} (lần tới ${_formatDateTime(scheduledDate)}), '
            'id=${100 + weekday}.',
          );
        }
        return;
      }

      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
        debugPrint(
          '[NotificationService] Nền tảng ${defaultTargetPlatform.name} không được cấu hình lịch nhắc giờ đi ngủ.',
        );
        return;
      }

      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime? nextReminder;
      for (var offset = 0; offset <= DateTime.daysPerWeek; offset++) {
        final candidate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + offset,
          hour,
          minute,
        );
        if (selectedDays.contains(candidate.weekday) &&
            candidate.isAfter(now)) {
          nextReminder = candidate;
          break;
        }
      }

      if (nextReminder == null) {
        debugPrint(
          '[NotificationService] Không tìm thấy thời điểm nhắc giờ đi ngủ sắp tới.',
        );
        return;
      }

      await _notificationsPlugin.zonedSchedule(
        id: 100,
        title: title,
        body: body,
        scheduledDate: nextReminder,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      final platform = kIsWeb ? 'Web' : 'Windows';
      debugPrint(
        '[NotificationService] Đã lên lịch một lần trên $platform: '
        '${_weekdayName(nextReminder.weekday)} ${_formatDateTime(nextReminder)}, id=100.',
      );
    } on UnsupportedError catch (e) {
      final platform = kIsWeb ? 'Web' : defaultTargetPlatform.name;
      debugPrint(
        '[NotificationService] Nền tảng $platform không hỗ trợ lên lịch nhắc giờ đi ngủ: $e',
      );
    } catch (e) {
      debugPrint('[NotificationService] Lỗi lên lịch nhắc giờ đi ngủ: $e');
    }
  }

  String _weekdayName(int weekday) => const {
    DateTime.monday: 'T2',
    DateTime.tuesday: 'T3',
    DateTime.wednesday: 'T4',
    DateTime.thursday: 'T5',
    DateTime.friday: 'T6',
    DateTime.saturday: 'T7',
    DateTime.sunday: 'CN',
  }[weekday]!;

  String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.year.toString().padLeft(4, '0')}-'
      '${dateTime.month.toString().padLeft(2, '0')}-'
      '${dateTime.day.toString().padLeft(2, '0')} '
      '${_formatTime(dateTime.hour, dateTime.minute)}';

  Future<void> cancelAllReminders() async {
    debugPrint('[NotificationService] Đã hủy toàn bộ lịch nhắc nhở.');
  }
}
