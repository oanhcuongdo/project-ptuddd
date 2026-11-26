import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import 'data/app_database.dart';
import 'services/firebase_backend.dart';
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
    if (u == null) {
      await NotificationService.cancel();
      return;
    }
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
    if (FirebaseRuntime.enabled &&
        auth.FirebaseAuth.instance.currentUser != null) {
      final uid = auth.FirebaseAuth.instance.currentUser!.uid;
      final rate = stats!.rate;
      if (rate != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'rate': rate.value,
            'rateLevel': rate.level.label,
            'attemptCount': rate.attempts,
          });
        } on FirebaseException {
          // A transient network/rules error must not block local practice.
        }
      }
    }
    if (u.reminderEnabled) {
      await NotificationService.scheduleDaily(
        u.reminderHour,
        u.reminderMinute,
        stats!.streak,
        practicedToday: stats!.practicedToday,
      );
    } else {
      await NotificationService.cancel();
    }
  }

  Future<void> updateSettings({
    int? goal,
    bool? reminder,
    int? hour,
    int? minute,
  }) async {
    user = await db.updateSettings(
      user!,
      goal: goal,
      reminder: reminder,
      hour: hour,
      minute: minute,
    );
    if (reminder == true) await NotificationService.requestPermission();
    await refresh();
  }
}
