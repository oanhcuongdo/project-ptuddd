import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/drill_item.dart';

enum DrillTimerStatus {
  idle,
  running,
  paused,
  resting,
  completed,
}

class DrillTimerService extends ChangeNotifier {
  DrillItem? _selectedDrill;
  int _currentSet = 1;
  int _remainingSeconds = 0;
  int _totalElapsedSeconds = 0;
  DrillTimerStatus _status = DrillTimerStatus.idle;
  bool _isPausedFromRest = false;

  Timer? _timer;

  VoidCallback? onSetCompleted;
  VoidCallback? onRestCompleted;
  VoidCallback? onSessionCompleted;

  DrillItem? get selectedDrill => _selectedDrill;
  int get currentSet => _currentSet;
  int get remainingSeconds => _remainingSeconds;
  int get totalElapsedSeconds => _totalElapsedSeconds;
  DrillTimerStatus get status => _status;

  int get totalSets => _selectedDrill?.sets ?? 1;

  bool get isIdle => _status == DrillTimerStatus.idle;
  bool get isRunning => _status == DrillTimerStatus.running;
  bool get isPaused => _status == DrillTimerStatus.paused;
  bool get isResting => _status == DrillTimerStatus.resting;
  bool get isCompleted => _status == DrillTimerStatus.completed;

  int get currentPhaseTotalSeconds {
    if (_selectedDrill == null) return 1;
    if (_status == DrillTimerStatus.resting ||
        (_status == DrillTimerStatus.paused && _isPausedFromRest)) {
      return _selectedDrill!.restSeconds > 0 ? _selectedDrill!.restSeconds : 1;
    }
    return _selectedDrill!.durationSeconds > 0
        ? _selectedDrill!.durationSeconds
        : 1;
  }

  double get progress {
    final total = currentPhaseTotalSeconds;
    if (total <= 0) return 0.0;
    return (_remainingSeconds / total).clamp(0.0, 1.0);
  }

  String get formattedRemainingTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get actualMinutesTrained {
    if (_totalElapsedSeconds == 0) return 0;
    return (_totalElapsedSeconds / 60).ceil();
  }

  void selectDrill(DrillItem drill) {
    _stopTimer();
    _selectedDrill = drill;
    _currentSet = 1;
    _remainingSeconds = drill.durationSeconds;
    _totalElapsedSeconds = 0;
    _status = DrillTimerStatus.idle;
    _isPausedFromRest = false;
    notifyListeners();
  }

  void start() {
    if (_selectedDrill == null) return;
    if (_status == DrillTimerStatus.running) return;

    if (_status == DrillTimerStatus.completed) {
      reset();
    }

    _status = DrillTimerStatus.running;
    _startPeriodicTimer();
    notifyListeners();
  }

  void pause() {
    if (_status != DrillTimerStatus.running &&
        _status != DrillTimerStatus.resting) {
      return;
    }
    _isPausedFromRest = (_status == DrillTimerStatus.resting);
    _stopTimer();
    _status = DrillTimerStatus.paused;
    notifyListeners();
  }

  void resume() {
    if (_status != DrillTimerStatus.paused) return;
    _status = _isPausedFromRest
        ? DrillTimerStatus.resting
        : DrillTimerStatus.running;
    _startPeriodicTimer();
    notifyListeners();
  }

  void reset() {
    _stopTimer();
    if (_selectedDrill != null) {
      _currentSet = 1;
      _remainingSeconds = _selectedDrill!.durationSeconds;
      _totalElapsedSeconds = 0;
    }
    _status = DrillTimerStatus.idle;
    _isPausedFromRest = false;
    notifyListeners();
  }

  void nextSetOrFinish() {
    if (_selectedDrill == null) return;
    _stopTimer();

    if (_currentSet < _selectedDrill!.sets) {
      if (_selectedDrill!.restSeconds > 0 &&
          _status != DrillTimerStatus.resting) {
        _status = DrillTimerStatus.resting;
        _remainingSeconds = _selectedDrill!.restSeconds;
        _isPausedFromRest = false;
        onSetCompleted?.call();
        _startPeriodicTimer();
      } else {
        _startNextSet();
      }
    } else {
      _completeSession();
    }
    notifyListeners();
  }

  void skipRest() {
    if (_status != DrillTimerStatus.resting &&
        !(_status == DrillTimerStatus.paused && _isPausedFromRest)) {
      return;
    }
    _stopTimer();
    _startNextSet();
    notifyListeners();
  }

  void finishSessionEarly() {
    _stopTimer();
    _completeSession();
    notifyListeners();
  }

  void _startNextSet() {
    if (_selectedDrill == null) return;
    _currentSet++;
    _status = DrillTimerStatus.running;
    _remainingSeconds = _selectedDrill!.durationSeconds;
    _isPausedFromRest = false;
    onRestCompleted?.call();
    _startPeriodicTimer();
  }

  void _completeSession() {
    _stopTimer();
    _remainingSeconds = 0;
    _status = DrillTimerStatus.completed;
    _isPausedFromRest = false;
    onSessionCompleted?.call();
  }

  void _startPeriodicTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        if (_status == DrillTimerStatus.running) {
          _totalElapsedSeconds++;
        }
        notifyListeners();
      } else {
        _handlePhaseFinished();
      }
    });
  }

  void _handlePhaseFinished() {
    if (_selectedDrill == null) return;
    _stopTimer();

    if (_status == DrillTimerStatus.running) {
      if (_currentSet < _selectedDrill!.sets) {
        if (_selectedDrill!.restSeconds > 0) {
          _status = DrillTimerStatus.resting;
          _remainingSeconds = _selectedDrill!.restSeconds;
          onSetCompleted?.call();
          _startPeriodicTimer();
        } else {
          _startNextSet();
        }
      } else {
        _completeSession();
      }
    } else if (_status == DrillTimerStatus.resting) {
      _startNextSet();
    }
    notifyListeners();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
