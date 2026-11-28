import 'dart:async';

import 'package:flutter/material.dart';

import '../data/database/database_helper.dart';
import '../data/models/sleep_goal_model.dart';
import '../data/models/sleep_record_model.dart';
import '../data/services/notification_service.dart';
import '../data/services/supabase_service.dart';

class SleepProvider extends ChangeNotifier {
  SleepGoalModel _goal = SleepGoalModel(
    bedtimeHour: 23,
    bedtimeMinute: 0,
    wakeHour: 7,
    wakeMinute: 0,
    targetDurationHours: 8.0,
  );
  List<SleepRecordModel> _records = [];
  bool _isLoading = true;
  bool _hasSyncedInitialReminder = false;

  SleepGoalModel get goal => _goal;
  List<SleepRecordModel> get records => _records;
  bool get isLoading => _isLoading;

  SleepRecordModel? get latestRecord =>
      _records.isNotEmpty ? _records.first : null;

  // Discipline & Compliance Rate (%)
  double get complianceRate {
    if (_records.isEmpty) return 100.0;
    final recent = _records.take(7).toList();
    final metCount = recent.where((r) => r.isGoalMet).length;
    return (metCount / recent.length) * 100.0;
  }

  // Average sleep duration of recent 7 days
  double get averageDurationHours {
    if (_records.isEmpty) return _goal.targetDurationHours;
    final recent = _records.take(7).toList();
    final total = recent.fold<double>(0.0, (sum, r) => sum + r.durationHours);
    return total / recent.length;
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _goal = await DatabaseHelper.instance.getSleepGoal();
    _records = await DatabaseHelper.instance.getSleepRecords();

    if (!_hasSyncedInitialReminder) {
      _hasSyncedInitialReminder = true;
      if (_goal.isReminderEnabled) {
        try {
          await _syncBedtimeReminder();
        } catch (e) {
          debugPrint(
            '[SleepProvider] Lỗi lên lịch lại nhắc giờ đi ngủ khi mở app: $e',
          );
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateGoal({
    required int bedtimeHour,
    required int bedtimeMinute,
    required int wakeHour,
    required int wakeMinute,
    required double targetDurationHours,
    required String activeDays,
  }) async {
    _goal = SleepGoalModel(
      id: _goal.id,
      bedtimeHour: bedtimeHour,
      bedtimeMinute: bedtimeMinute,
      wakeHour: wakeHour,
      wakeMinute: wakeMinute,
      targetDurationHours: targetDurationHours,
      activeDays: activeDays,
      isReminderEnabled: _goal.isReminderEnabled,
    );
    await DatabaseHelper.instance.updateSleepGoal(_goal);
    unawaited(SupabaseService.instance.syncSleepGoal(_goal));
    await _syncBedtimeReminder();
    notifyListeners();
  }

  Future<void> setReminderEnabled(bool value) async {
    _goal = SleepGoalModel(
      id: _goal.id,
      bedtimeHour: _goal.bedtimeHour,
      bedtimeMinute: _goal.bedtimeMinute,
      wakeHour: _goal.wakeHour,
      wakeMinute: _goal.wakeMinute,
      targetDurationHours: _goal.targetDurationHours,
      activeDays: _goal.activeDays,
      isReminderEnabled: value,
    );
    await DatabaseHelper.instance.updateSleepGoal(_goal);
    unawaited(SupabaseService.instance.syncSleepGoal(_goal));
    await _syncBedtimeReminder();
    notifyListeners();
  }

  Future<void> _syncBedtimeReminder() async {
    if (_goal.isReminderEnabled) {
      await NotificationService.instance.scheduleBedtimeReminder(
        hour: _goal.bedtimeHour,
        minute: _goal.bedtimeMinute,
        title: 'Đến giờ đi ngủ rồi',
        body: 'Đã đến giờ đi ngủ theo lịch bạn đặt. Chuẩn bị nghỉ thôi!',
        activeDays: _goal.activeDays,
      );
    } else {
      await NotificationService.instance.cancelBedtimeReminders();
    }
  }

  Future<void> addSleepRecord({
    required DateTime sleepTime,
    required DateTime wakeTime,
    required int feelingRating,
    required int wakeUpCount,
    required String note,
  }) async {
    final duration = wakeTime.difference(sleepTime).inMinutes / 60.0;
    final isGoalMet = duration >= (_goal.targetDurationHours - 0.5);

    final record = SleepRecordModel(
      sleepTime: sleepTime,
      wakeTime: wakeTime,
      durationHours: duration,
      wakeUpCount: wakeUpCount,
      feelingRating: feelingRating,
      note: note,
      isGoalMet: isGoalMet,
      createdAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertSleepRecord(record);
    unawaited(SupabaseService.instance.syncSleepRecord(record));
    await loadData();
  }

  // Cập nhật nhật ký giấc ngủ
  Future<void> updateSleepRecord(SleepRecordModel record) async {
    if (record.id == null) return;

    await DatabaseHelper.instance.updateSleepRecord(record);
    await loadData();
  }

  // Xóa nhật ký giấc ngủ
  Future<void> deleteSleepRecord(int id) async {
    await DatabaseHelper.instance.deleteSleepRecord(id);
    await loadData();
  }
}
