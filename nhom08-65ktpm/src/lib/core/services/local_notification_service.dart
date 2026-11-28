import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/goal_and_checklist/models/checklist_item.dart';
import '../../features/saving_discipline_and_momo/models/deposit_record.dart';
import '../../features/saving_discipline_and_momo/models/saving_plan.dart';
import '../../features/saving_discipline_and_momo/utils/momo_deeplink_helper.dart';
import '../../features/saving_discipline_and_momo/utils/saving_streak_calculator.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => LocalNotificationService(),
);

/// Schedules and cancels OS local notifications for checklist due-date reminders.
class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'travel_buddy_checklist_reminders';
  static const String _channelName = 'Nhắc việc chuẩn bị chuyến đi';
  static const String _channelDescription =
      'Thông báo nhắc các đầu việc sắp đến hạn trước ngày khởi hành';

  static bool _initialized = false;
  static bool _tzInitialized = false;

  final FlutterLocalNotificationsPlugin _plugin;
  final Map<String, String> _syncedSignatures = <String, String>{};

  static bool get isInitialized => _initialized;

  static void _ensureTimeZones() {
    if (_tzInitialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    _tzInitialized = true;
  }

  /// Initializes local notifications safely (no-op in widget tests or unsupported envs).
  static Future<void> initializeSafely() async {
    _ensureTimeZones();
    if (_initialized || kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await FlutterLocalNotificationsPlugin().initialize(settings: settings);
      _initialized = true;
    } catch (e) {
      debugPrint('Local notifications initialization skipped: $e');
    }
  }

  /// Requests OS notification permission when triggered from an interactive mobile flow.
  Future<void> requestPermissionIfNeeded() async {
    if (!_initialized || kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      debugPrint('Notification permission request skipped: $e');
    }
  }

  /// Computes a deterministic positive 31-bit notification id for [itemId].
  static int notificationIdForItem(String itemId) {
    var hash = 0;
    for (final unit in itemId.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  /// Returns the target local reminder timestamp for [item], or `null` when
  /// the item is completed, lacks a due date, or the reminder window has passed.
  static DateTime? computeReminderScheduleTime(
    ChecklistItem item, {
    DateTime? now,
  }) {
    if (item.isCompleted || item.dueDate == null) return null;
    final ref = now ?? DateTime.now();
    final due = item.dueDate!;
    final dayBeforeMorning = DateTime(due.year, due.month, due.day - 1, 9, 0);
    if (dayBeforeMorning.isAfter(ref)) {
      return dayBeforeMorning;
    }
    final dueDayMorning = DateTime(due.year, due.month, due.day, 9, 0);
    if (dueDayMorning.isAfter(ref)) {
      return dueDayMorning;
    }
    return null;
  }

  /// Syncs pending OS reminders for all [items], cancelling completed or removed items.
  Future<void> syncChecklistReminders(List<ChecklistItem> items) async {
    if (!_initialized || kIsWeb) return;
    _ensureTimeZones();

    final currentIds = <String>{};
    for (final item in items) {
      currentIds.add(item.id);
      final scheduledAt = computeReminderScheduleTime(item);
      final signature =
          '${item.title}|${item.isCompleted}|${scheduledAt?.millisecondsSinceEpoch}';
      if (_syncedSignatures[item.id] == signature) continue;
      _syncedSignatures[item.id] = signature;

      final notifId = notificationIdForItem(item.id);
      if (scheduledAt == null) {
        await _cancelSafe(notifId);
        continue;
      }

      await _scheduleSafe(
        id: notifId,
        title: 'Nhắc việc chuẩn bị chuyến đi',
        body: 'Sắp đến hạn: "${item.title}"',
        scheduledAt: scheduledAt,
        payload: 'checklist:${item.tripId}:${item.id}',
      );
    }

    final removedIds =
        _syncedSignatures.keys.where((id) => !currentIds.contains(id)).toList();
    for (final id in removedIds) {
      _syncedSignatures.remove(id);
      await _cancelSafe(notificationIdForItem(id));
    }
  }

  /// Returns the target local reminder timestamp for the next saving deposit, or `null`
  /// when the plan is completed or no future reminder window exists.
  static DateTime? computeSavingReminderScheduleTime({
    required SavingPlan plan,
    required List<DepositRecord> deposits,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final nextIncoming = SavingStreakCalculator.nextIncomingDeposit(
      plan: plan,
      deposits: deposits,
      today: ref,
    );
    if (nextIncoming == null) return null;

    final due = nextIncoming.dueDate;
    final dueMorning = DateTime(due.year, due.month, due.day, 9, 0);
    if (dueMorning.isAfter(ref)) {
      return dueMorning;
    }
    final dueEvening = DateTime(due.year, due.month, due.day, 19, 0);
    if (dueEvening.isAfter(ref)) {
      return dueEvening;
    }
    return null;
  }

  /// Schedules or cancels an OS local reminder for a member's next saving deposit.
  Future<void> syncSavingPlanReminder({
    required SavingPlan? plan,
    required List<DepositRecord> memberDeposits,
    required String tripId,
    required String memberId,
  }) async {
    if (!_initialized || kIsWeb) return;
    _ensureTimeZones();

    final key = 'saving:$tripId:$memberId';
    final notifId = notificationIdForItem(key);
    if (plan == null) {
      _syncedSignatures.remove(key);
      await _cancelSafe(notifId);
      return;
    }

    final scheduledAt = computeSavingReminderScheduleTime(
      plan: plan,
      deposits: memberDeposits,
    );
    final nextIncoming = SavingStreakCalculator.nextIncomingDeposit(
      plan: plan,
      deposits: memberDeposits,
    );
    final signature =
        '${plan.status.name}|${plan.completedInstallments}|${scheduledAt?.millisecondsSinceEpoch}|${nextIncoming?.amount.round()}';
    if (_syncedSignatures[key] == signature) return;
    _syncedSignatures[key] = signature;

    if (scheduledAt == null || nextIncoming == null) {
      await _cancelSafe(notifId);
      return;
    }

    final amountStr = MoMoDeeplinkHelper.formatVnd(nextIncoming.amount.round());
    await _scheduleSafe(
      id: notifId,
      title: 'Nhắc đóng quỹ MoMo',
      body: 'Kỳ ${nextIncoming.installmentIndex}: cần đóng $amountStr để giữ chuỗi kỷ luật.',
      scheduledAt: scheduledAt,
      payload: key,
    );
  }

  Future<void> _scheduleSafe({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  }) async {
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Schedule checklist notification skipped: $e');
    }
  }

  Future<void> _cancelSafe(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Cancel checklist notification skipped: $e');
    }
  }
}
