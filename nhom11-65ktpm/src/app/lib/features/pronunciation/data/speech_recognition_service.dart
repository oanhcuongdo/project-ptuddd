import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

enum SpeechServiceStatus {
  uninitialized,
  initializing,
  ready,
  listening,
  done,
  notAvailable,
  error,
}

class SpeechRecognitionService {
  final SpeechToText _speechToText = SpeechToText();
  
  SpeechServiceStatus _status = SpeechServiceStatus.uninitialized;
  SpeechServiceStatus get status => _status;

  String _lastRecognizedWords = '';
  String get lastRecognizedWords => _lastRecognizedWords;

  final _statusController = StreamController<SpeechServiceStatus>.broadcast();
  Stream<SpeechServiceStatus> get statusStream => _statusController.stream;

  final _recognizedTextController = StreamController<String>.broadcast();
  Stream<String> get recognizedTextStream => _recognizedTextController.stream;

  final _soundLevelController = StreamController<double>.broadcast();
  Stream<double> get soundLevelStream => _soundLevelController.stream;

  void _updateStatus(SpeechServiceStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  Future<bool> initialize() async {
    if (_status == SpeechServiceStatus.ready) return true;

    _updateStatus(SpeechServiceStatus.initializing);
    try {
      final available = await _speechToText.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: kDebugMode,
      );

      if (available) {
        _updateStatus(SpeechServiceStatus.ready);
        return true;
      } else {
        _updateStatus(SpeechServiceStatus.notAvailable);
        return false;
      }
    } catch (e) {
      debugPrint('Loi khoi tao SpeechToText: $e');
      _updateStatus(SpeechServiceStatus.error);
      return false;
    }
  }

  void _handleStatus(String statusStr) {
    switch (statusStr) {
      case 'listening':
        _updateStatus(SpeechServiceStatus.listening);
        break;
      case 'notListening':
      case 'done':
        _updateStatus(SpeechServiceStatus.done);
        break;
      default:
        break;
    }
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint('Loi nhan dang giong noi: ${error.errorMsg} - permanent: ${error.permanent}');
    _updateStatus(SpeechServiceStatus.error);
  }

  Future<bool> startListening({
    String localeId = 'zh-CN',
    Duration listenFor = const Duration(seconds: 15),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    final isReady = await initialize();
    if (!isReady) return false;

    _lastRecognizedWords = '';
    _recognizedTextController.add('');

    try {
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _lastRecognizedWords = result.recognizedWords;
          _recognizedTextController.add(_lastRecognizedWords);
        },
        onSoundLevelChange: (level) {
          _soundLevelController.add(level);
        },
        listenOptions: SpeechListenOptions(
          listenFor: listenFor,
          pauseFor: pauseFor,
          localeId: localeId,
          cancelOnError: false,
          partialResults: true,
        ),
      );
      _updateStatus(SpeechServiceStatus.listening);
      return true;
    } catch (e) {
      debugPrint('Khong the bat dau lang nghe: $e');
      _updateStatus(SpeechServiceStatus.error);
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      _updateStatus(SpeechServiceStatus.done);
    } catch (e) {
      debugPrint('Loi khi dung lang nghe: $e');
    }
  }

  Future<void> cancelListening() async {
    try {
      await _speechToText.cancel();
      _updateStatus(SpeechServiceStatus.ready);
    } catch (e) {
      debugPrint('Loi khi huy lang nghe: $e');
    }
  }

  Future<void> dispose() async {
    await _statusController.close();
    await _recognizedTextController.close();
    await _soundLevelController.close();
  }
}
