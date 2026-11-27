import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum AudioRecordingState {
  initial,
  ready,
  recording,
  paused,
  stopped,
  error,
}

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  
  AudioRecordingState _state = AudioRecordingState.initial;
  AudioRecordingState get state => _state;

  StreamSubscription<RecordState>? _recordSub;
  StreamSubscription<Amplitude>? _amplitudeSub;

  final _stateController = StreamController<AudioRecordingState>.broadcast();
  Stream<AudioRecordingState> get stateStream => _stateController.stream;

  final _amplitudeController = StreamController<double>.broadcast();
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  String? _currentAudioPath;
  String? get currentAudioPath => _currentAudioPath;

  AudioRecordingService() {
    _recordSub = _recorder.onStateChanged().listen((recordState) {
      switch (recordState) {
        case RecordState.record:
          _updateState(AudioRecordingState.recording);
          break;
        case RecordState.pause:
          _updateState(AudioRecordingState.paused);
          break;
        case RecordState.stop:
          _updateState(AudioRecordingState.stopped);
          break;
      }
    });
  }

  void _updateState(AudioRecordingState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  Future<bool> requestMicrophonePermission() async {
    try {
      final hasPerm = await _recorder.hasPermission();
      if (hasPerm) {
        _updateState(AudioRecordingState.ready);
        return true;
      } else {
        _updateState(AudioRecordingState.error);
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting mic permission: $e');
      _updateState(AudioRecordingState.error);
      return false;
    }
  }

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<String?> startRecording({String? customFileName}) async {
    try {
      final hasPerm = await hasPermission();
      if (!hasPerm) {
        final granted = await requestMicrophonePermission();
        if (!granted) {
          throw Exception('Chua duoc cap quyen Microphone');
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/chailish_recordings');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final fileName = customFileName ?? 'rec_${DateTime.now().millisecondsSinceEpoch}.wav';
      final filePath = '${audioDir.path}/$fileName';
      _currentAudioPath = filePath;

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 128000,
      );

      await _recorder.start(config, path: filePath);
      _updateState(AudioRecordingState.recording);

      _startAmplitudeMonitoring();

      return filePath;
    } catch (e) {
      debugPrint('Loi khi bat dau thu am: $e');
      _updateState(AudioRecordingState.error);
      return null;
    }
  }

  void _startAmplitudeMonitoring() {
    _amplitudeSub?.cancel();
    _amplitudeSub = Stream.periodic(const Duration(milliseconds: 100))
        .asyncMap((_) => _recorder.getAmplitude())
        .listen((amp) {
      final normalized = _normalizeDb(amp.current);
      _amplitudeController.add(normalized);
    });
  }

  double _normalizeDb(double currentDb) {
    if (currentDb < -60) return 0.0;
    if (currentDb > 0) return 1.0;
    return (currentDb + 60) / 60;
  }

  Future<String?> stopRecording() async {
    try {
      _amplitudeSub?.cancel();
      _amplitudeSub = null;
      final path = await _recorder.stop();
      _updateState(AudioRecordingState.stopped);
      _currentAudioPath = path ?? _currentAudioPath;
      return _currentAudioPath;
    } catch (e) {
      debugPrint('Loi khi dung thu am: $e');
      _updateState(AudioRecordingState.error);
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      _amplitudeSub?.cancel();
      _amplitudeSub = null;
      await _recorder.cancel();
      _updateState(AudioRecordingState.ready);
      if (_currentAudioPath != null) {
        final file = File(_currentAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentAudioPath = null;
      }
    } catch (e) {
      debugPrint('Loi khi huy thu am: $e');
    }
  }

  Future<void> dispose() async {
    _amplitudeSub?.cancel();
    _recordSub?.cancel();
    await _stateController.close();
    await _amplitudeController.close();
    await _recorder.dispose();
  }
}
