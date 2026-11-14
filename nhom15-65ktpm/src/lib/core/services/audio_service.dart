import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsInitialized = false;

  AudioService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('vi-VN');
      await _flutterTts.setSpeechRate(0.45); // Tốc độ vừa phải cho trẻ 4-6 tuổi
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.2); // Âm điệu hoạt hình thân thiện
      _isTtsInitialized = true;
    } catch (_) {
      _isTtsInitialized = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_isTtsInitialized) {
      await _initTts();
    }
    try {
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  Future<void> playBeadClick() async {
    // Phản hồi rung nhẹ xúc giác ngay lập tức khi gảy hạt
    await HapticFeedback.lightImpact();
  }

  Future<void> playSuccessFeedback() async {
    await HapticFeedback.mediumImpact();
    await speak('Hoan hô bé, đúng rồi!');
  }

  Future<void> playEncouragementFeedback() async {
    await HapticFeedback.selectionClick();
    await speak('Bé thử lại một lần nữa nhé!');
  }
}
