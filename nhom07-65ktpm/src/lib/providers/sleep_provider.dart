import 'package:flutter/material.dart';
import '../data/database/database_helper.dart';
import '../data/models/sleep_goal_model.dart';
import '../data/models/sleep_record_model.dart';

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

  SleepGoalModel get goal => _goal;
  List<SleepRecordModel> get records => _records;
  bool get isLoading => _isLoading;

  SleepRecordModel? get latestRecord => _records.isNotEmpty ? _records.first : null;

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
    notifyListeners();
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
    await loadData();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}

