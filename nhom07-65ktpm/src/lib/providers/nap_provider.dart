import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../data/database/database_helper.dart';
import '../data/models/nap_record_model.dart';

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
    unawaited(_recordCompletedNap());
  }

  Future<void> _recordCompletedNap() async {
    final nap = NapRecordModel(
      startTime: DateTime.now().subtract(
        Duration(minutes: _selectedPresetMinutes),
      ),
      durationMinutes: _selectedPresetMinutes,
      note: 'Hoàn thành giấc ngủ ngắn $_selectedPresetMinutes phút.',
    );
    await DatabaseHelper.instance.insertNapRecord(nap);
    await loadHistory();
  }

  Future<void> loadHistory() async {
    _napHistory = await DatabaseHelper.instance.getNapRecords();
    notifyListeners();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
