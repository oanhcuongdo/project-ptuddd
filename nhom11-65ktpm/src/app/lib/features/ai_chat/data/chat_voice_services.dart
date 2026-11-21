import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Đọc mẫu câu tiếng Trung cho màn hình trò chuyện AI.
///
/// Bản cài đặt mặc định dùng `flutter_tts` (zh-CN). Khi dịch vụ TTS dùng chung
/// của module phát âm (#12) hoàn thành, chỉ cần override [chatTtsProvider].
abstract class ChatTts {
  Future<void> speak(String text, {bool slow = false});
  Future<void> stop();
}

/// Nhận dạng giọng nói zh-CN để người học trả lời bằng cách nói.
///
/// Bản mặc định dùng `speech_to_text`; có thể thay bằng dịch vụ thu âm / nhận
/// dạng dùng chung (#11) bằng cách override [chatSpeechInputProvider].
abstract class ChatSpeechInput {
  Future<bool> initialize();

  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  });

  Future<void> stop();
}

final chatTtsProvider = Provider<ChatTts>((ref) {
  final tts = FlutterChatTts();
  ref.onDispose(tts.stop);
  return tts;
});

final chatSpeechInputProvider = Provider<ChatSpeechInput>((ref) {
  final speech = SpeechToTextChatInput();
  ref.onDispose(speech.stop);
  return speech;
});

class FlutterChatTts implements ChatTts {
  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  @override
  Future<void> speak(String text, {bool slow = false}) async {
    if (!_configured) {
      await _tts.setLanguage('zh-CN');
      _configured = true;
    }
    await _tts.stop();
    await _tts.setSpeechRate(slow ? 0.3 : 0.5);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}

class SpeechToTextChatInput implements ChatSpeechInput {
  final SpeechToText _speech = SpeechToText();
  bool _ready = false;

  @override
  Future<bool> initialize() async {
    if (_ready) return true;
    _ready = await _speech.initialize();
    return _ready;
  }

  @override
  Future<void> listen({required void Function(String text, bool isFinal) onResult}) async {
    if (!await initialize()) return;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) =>
          onResult(result.recognizedWords, result.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: 'zh_CN',
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();
}
