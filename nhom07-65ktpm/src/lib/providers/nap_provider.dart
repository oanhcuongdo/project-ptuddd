import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../data/database/database_helper.dart';
import '../data/models/nap_record_model.dart';
import '../data/services/notification_service.dart';
import '../data/services/supabase_service.dart';

enum NapStatus { notStarted, running, paused, completed }

class NapProvider extends ChangeNotifier {
  int _selectedPresetMinutes = 20;
  int _remainingSeconds = 20 * 60;
  NapStatus _status = NapStatus.notStarted;
  Timer? _timer;
  List<NapRecordModel> _napHistory = [];

  int get selectedPresetMinutes => _selectedPresetMinutes;
  int get remainingSeconds => _remainingSeconds;
  NapStatus get status => _status;
  bool get isRunning => _status == NapStatus.running;
  bool get isCompleted => _status == NapStatus.completed;
  List<NapRecordModel> get napHistory => _napHistory;

  double get progress {
    final total = _selectedPresetMinutes * 60;
    if (total == 0) return 0;
    return 1.0 - (_remainingSeconds / total);
  }

  String get formattedRemainingTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void selectPreset(int minutes) {
    if (!AppConstants.napPresetsMinutes.contains(minutes)) {
      throw ArgumentError.value(minutes, 'minutes', 'Unsupported nap duration');
    }
    if (isRunning) return;
    _selectedPresetMinutes = minutes;
    _remainingSeconds = minutes * 60;
    _status = NapStatus.notStarted;
    notifyListeners();
  }

  void selectCustomDuration(int minutes) {
    if (minutes < 1 || minutes > 180) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        'Custom duration must be between 1 and 180 minutes',
      );
    }
    if (isRunning) return;
    _selectedPresetMinutes = minutes;
    _remainingSeconds = minutes * 60;
    _status = NapStatus.notStarted;
    notifyListeners();
  }

  void startTimer() {
    if (isRunning || _status == NapStatus.paused) return;
    if (isCompleted) {
      _remainingSeconds = _selectedPresetMinutes * 60;
    }
    _startCountdown();
  }

  void _startCountdown() {
    _status = NapStatus.running;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _remainingSeconds = 0;
        _completeTimer();
      }
    });
    notifyListeners();
  }

  void pauseTimer() {
    if (!isRunning) return;
    _timer?.cancel();
    _timer = null;
    _status = NapStatus.paused;
    notifyListeners();
  }

  void resumeTimer() {
    if (_status != NapStatus.paused) return;
    _startCountdown();
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _status = NapStatus.notStarted;
    _remainingSeconds = _selectedPresetMinutes * 60;
    notifyListeners();
  }

  void resetTimer() => cancelTimer();

  void _completeTimer() {
    _timer?.cancel();
    _timer = null;
    _status = NapStatus.completed;
    notifyListeners();
    unawaited(_recordCompletedNap(_selectedPresetMinutes));
  }

  Future<void> _recordCompletedNap(int completedMinutes) async {
    final nap = NapRecordModel(
      startTime: DateTime.now().subtract(
        Duration(minutes: completedMinutes),
      ),
      durationMinutes: completedMinutes,
      note: 'Hoàn thành giấc ngủ ngắn $completedMinutes phút.',
    );
    await DatabaseHelper.instance.insertNapRecord(nap);
    unawaited(SupabaseService.instance.syncNapRecord(nap));
    await loadHistory();
    await NotificationService.instance.showNow(
      title: 'Đã hết giờ ngủ ngắn',
      body: 'Giấc ngủ ngắn $completedMinutes phút đã kết thúc, dậy thôi!',
    );
  }

  Future<void> loadHistory() async {
    _napHistory = await DatabaseHelper.instance.getNapRecords();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
