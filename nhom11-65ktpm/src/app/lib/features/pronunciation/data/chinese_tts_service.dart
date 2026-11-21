import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsPlayState {
  stopped,
  playing,
  paused,
}

class ChineseTtsService {
  final FlutterTts _flutterTts = FlutterTts();
  TtsPlayState _state = TtsPlayState.stopped;
  TtsPlayState get state => _state;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.45); // Toc do doc chuan tu nhien
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _state = TtsPlayState.playing;
      });

      _flutterTts.setCompletionHandler(() {
        _state = TtsPlayState.stopped;
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _state = TtsPlayState.stopped;
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Loi khoi tao TTS tieng Trung: $e');
    }
  }

  Future<void> speak(String text, {bool slow = false}) async {
    await initialize();
    try {
      final rate = slow ? 0.25 : 0.45;
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Loi khi phat am mau TTS: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _state = TtsPlayState.stopped;
    } catch (e) {
      debugPrint('Loi khi dung TTS: $e');
    }
  }
}
