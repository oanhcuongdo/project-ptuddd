import 'package:flutter/foundation.dart';

import 'data/app_database.dart';
import 'services/notification_service.dart';

class AppState extends ChangeNotifier {
  final AppDatabase db;
  User? user;
  Stats? stats;

  AppState(this.db);

  Future<void> selectUser(User? u) async {
    user = u;
    stats = null;
    notifyListeners();
    if (u == null) return;
    if (u.reminderEnabled) await NotificationService.requestPermission();
    await refresh();
  }

  /// Reloads stats and re-schedules the reminder so its text reflects the
  /// latest streak.
  Future<void> refresh() async {
    final u = user;
    if (u == null) return;
    stats = await db.stats(u.id);
    notifyListeners();
    if (u.reminderEnabled) {
      await NotificationService.scheduleDaily(u.reminderHour, u.reminderMinute, stats!.streak);
    } else {
      await NotificationService.cancel();
    }
  }

  Future<void> updateSettings({int? goal, bool? reminder, int? hour, int? minute}) async {
    user = await db.updateSettings(user!, goal: goal, reminder: reminder, hour: hour, minute: minute);
    if (reminder == true) await NotificationService.requestPermission();
    await refresh();
  }
}
